"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const defaultClaudeCmd = "C:\\Users\\Jorge\\AppData\\Roaming\\npm\\claude.cmd";
const defaultOllamaModel = "qwen2.5:14b-instruct-q4_K_M";
const providerStatePath = path.join(__dirname, "provider_state.json");
const transientRetryDelayMs = 5000;
const transientRetryCount = 1;
const maxCompactOutputLines = 12;

function compareVersionParts(left, right) {
  const maxLength = Math.max(left.length, right.length);
  for (let i = 0; i < maxLength; i += 1) {
    const leftPart = left[i] || 0;
    const rightPart = right[i] || 0;
    if (leftPart !== rightPart) {
      return leftPart - rightPart;
    }
  }
  return 0;
}

function parseChatGptExtensionVersion(dirname) {
  const match = String(dirname || "").match(/^openai\.chatgpt-([0-9]+(?:\.[0-9]+)*)-/i);
  if (!match) {
    return null;
  }

  return match[1]
    .split(".")
    .map((part) => Number.parseInt(part, 10))
    .filter((part) => Number.isFinite(part));
}

function listInstalledCodexCandidates() {
  if (process.platform !== "win32") {
    return [];
  }

  const homeDir = os.homedir();
  const extensionRoots = [
    path.join(homeDir, ".vscode", "extensions"),
    path.join(homeDir, ".vscode-insiders", "extensions"),
    path.join(homeDir, ".cursor", "extensions")
  ];

  const candidates = [];
  for (const extensionRoot of extensionRoots) {
    if (!fs.existsSync(extensionRoot)) {
      continue;
    }

    for (const entry of fs.readdirSync(extensionRoot, { withFileTypes: true })) {
      if (!entry.isDirectory()) {
        continue;
      }

      const versionParts = parseChatGptExtensionVersion(entry.name);
      if (!versionParts) {
        continue;
      }

      const codexPath = path.join(
        extensionRoot,
        entry.name,
        "bin",
        "windows-x86_64",
        "codex.exe"
      );
      if (!fs.existsSync(codexPath)) {
        continue;
      }

      candidates.push({
        path: codexPath,
        versionParts
      });
    }
  }

  return candidates.sort((left, right) => compareVersionParts(right.versionParts, left.versionParts));
}

function resolveCodexCommand() {
  if (process.env.CODEX_CMD) {
    return process.env.CODEX_CMD;
  }

  const installedCandidates = listInstalledCodexCandidates();
  if (installedCandidates.length > 0) {
    return installedCandidates[0].path;
  }

  return "codex";
}

function sleepMs(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function createCycleRunner(repoPath) {
  const promptPath = path.join(repoPath, "claude_cycle_prompt.txt");
  const fetchScriptPath = path.join(repoPath, "daily_external_fetch.js");
  const cycleContextPath = path.join(repoPath, "autonomous_cycle_context.json");
  const questionsPath = path.join(repoPath, "inst", "extdata", "questions.csv");
  const knowledgePath = path.join(repoPath, "inst", "extdata", "knowledge_repository.csv");
  const reviewStatePath = path.join(repoPath, "AUTONOMOUS_REVIEW_STATE.md");
  const dailySummaryPath = path.join(repoPath, "daily_context", "summary.md");

  function runCommand(command, args, options = {}) {
    return spawnSync(command, args, {
      cwd: repoPath,
      encoding: "utf8",
      maxBuffer: 20 * 1024 * 1024,
      env: options.env || process.env,
      input: options.input,
      shell: false
    });
  }

  function commandExists(command) {
    if (!command) {
      return false;
    }

    if (path.isAbsolute(command)) {
      return fs.existsSync(command);
    }

    const resolver = process.platform === "win32" ? "where" : "which";
    const probe = spawnSync(resolver, [command], {
      cwd: repoPath,
      encoding: "utf8"
    });

    return !probe.error && probe.status === 0;
  }

  function readProviderState() {
    if (!fs.existsSync(providerStatePath)) {
      return {
        preferred_provider: null,
        last_success_provider: null,
        last_failure_class: null,
        updated_at: null
      };
    }

    try {
      return JSON.parse(fs.readFileSync(providerStatePath, "utf8"));
    } catch {
      return {
        preferred_provider: null,
        last_success_provider: null,
        last_failure_class: null,
        updated_at: null
      };
    }
  }

  function writeProviderState(nextState) {
    const payload = {
      preferred_provider: nextState.preferred_provider || null,
      last_success_provider: nextState.last_success_provider || null,
      last_failure_class: nextState.last_failure_class || null,
      updated_at: new Date().toISOString()
    };
    fs.writeFileSync(providerStatePath, JSON.stringify(payload, null, 2) + "\n", "utf8");
  }

  function reorderedProviderChain(defaultOrder) {
    const state = readProviderState();
    const preferred = state.preferred_provider;
    if (!preferred || !defaultOrder.includes(preferred)) {
      return defaultOrder.slice();
    }

    return [preferred].concat(defaultOrder.filter((provider) => provider !== preferred));
  }

  function buildClaudeEnv() {
    const env = { ...process.env };
    delete env.CLAUDECODE;
    delete env.CLAUDE_CODE_ENTRYPOINT;
    delete env.CLAUDE_CODE_ENABLE_SDK_FILE_WATCHING;
    return env;
  }

  function getAgentCommand(agentName) {
    if (agentName === "codex") {
      const command = resolveCodexCommand();
      return {
        command,
        args: [
          "exec",
          "--ephemeral",
          "--cd",
          repoPath,
          "--dangerously-bypass-approvals-and-sandbox",
          "-"
        ],
        inputMode: "stdin",
        env: process.env
      };
    }

    if (agentName === "claude") {
      const command = process.env.CLAUDE_CMD || defaultClaudeCmd;
      return {
        command,
        args: [
          "--print",
          "--dangerously-skip-permissions",
          "-p"
        ],
        inputMode: "arg",
        env: buildClaudeEnv()
      };
    }

    if (agentName === "ollama") {
      const command = process.env.OLLAMA_CMD || "ollama";
      const model = process.env.OLLAMA_MODEL || defaultOllamaModel;
      return {
        command,
        args: ["run", model],
        inputMode: "stdin",
        env: process.env
      };
    }

    throw new Error(`Unsupported agent '${agentName}'.`);
  }

  function classifyFailure(result) {
    const combined = cleanFailureText(
      [result.stdout, result.stderr, result.error && result.error.message]
        .filter(Boolean)
        .join("\n")
    );

    if (result.unavailable) {
      return "hard";
    }

    if (/429|rate.?limit|too many requests|quota|insufficient_quota|credit balance/i.test(combined)) {
      return "quota";
    }

    if (/timed out|timeout|temporar|econnreset|enotfound|network|socket hang up|fetch failed|aborted|ecanceled|connection reset|eai_again/i.test(combined)) {
      return "transient";
    }

    if (/unauthorized|forbidden|authentication|api key|invalid api key|access denied|permission|login required|not found|unknown option|invalid model|model .* not found/i.test(combined)) {
      return "hard";
    }

    if ((result.status ?? 1) !== 0) {
      return "hard";
    }

    return null;
  }

  function cleanFailureText(text) {
    return String(text || "").replace(/\s+/g, " ").trim();
  }

  function isNoisyAgentLine(line) {
    return (
      /^[+-]\d+,"/.test(line) ||
      /^diff --git /.test(line) ||
      /^index [0-9a-f]+\.\.[0-9a-f]+/.test(line) ||
      /^@@ /.test(line) ||
      /^[+-]{3} [ab]\//.test(line) ||
      /^commit [0-9a-f]{7,}/.test(line) ||
      /^System\.Management\.Automation\.RemoteException$/.test(line)
    );
  }

  function compactAgentOutput(stdoutText, stderrText) {
    const rawLines = [stdoutText || "", stderrText || ""]
      .join("\n")
      .split(/\r?\n/)
      .map((line) => line.trimEnd())
      .filter((line) => line.trim().length > 0);

    const kept = [];
    let suppressed = 0;

    for (let i = 0; i < rawLines.length; i += 1) {
      const line = rawLines[i].trim();

      if (/^tokens used$/i.test(line) && rawLines[i + 1]) {
        kept.push(`tokens used: ${rawLines[i + 1].trim()}`);
        i += 1;
        continue;
      }

      if (isNoisyAgentLine(line)) {
        suppressed += 1;
        continue;
      }

      if (/^(reading|searched|opened|applied patch|thinking|analyzing)\b/i.test(line)) {
        suppressed += 1;
        continue;
      }

      if (kept.length < maxCompactOutputLines) {
        kept.push(line);
      } else {
        suppressed += 1;
      }
    }

    if (suppressed > 0) {
      kept.push(`[cycle] Agent output compacted: suppressed ${suppressed} noisy line(s).`);
    }

    return kept;
  }

  function emitLines(lines, level = "log") {
    const method = level === "error" ? console.error : (level === "warn" ? console.warn : console.log);
    for (const line of lines) {
      method(line);
    }
  }

  function runAgentOnce(agentName, promptText) {
    const spec = getAgentCommand(agentName);
    if (!commandExists(spec.command)) {
      console.warn(`[cycle] Agent '${agentName}' unavailable: command not found (${spec.command}).`);
      return {
        ok: false,
        status: 127,
        stdout: "",
        stderr: `command not found: ${spec.command}`,
        error: null,
        unavailable: true
      };
    }

    console.log(`[cycle] Attempting agent '${agentName}'.`);
    const args = spec.inputMode === "arg"
      ? spec.args.concat([promptText])
      : spec.args;

    const result = runCommand(spec.command, args, {
      input: spec.inputMode === "stdin" ? promptText : undefined,
      env: spec.env
    });

    const status = result.status ?? 1;
    const ok = !result.error && status === 0;
    const compactedLines = compactAgentOutput(result.stdout || "", result.stderr || "");
    emitLines(compactedLines, ok ? "log" : "warn");

    return {
      ok,
      status,
      stdout: result.stdout || "",
      stderr: result.stderr || "",
      error: result.error || null,
      unavailable: false
    };
  }

  function runAgentWithPolicy(agentName, promptText) {
    let attempt = 0;

    while (attempt <= transientRetryCount) {
      const result = runAgentOnce(agentName, promptText);
      if (result.ok) {
        console.log(`[cycle] Agent '${agentName}' completed successfully.`);
        return { ok: true, agent: agentName, status: 0, failureClass: null };
      }

      const failureClass = classifyFailure(result);
      console.warn(`[cycle] Agent '${agentName}' failed. Class=${failureClass || "unknown"}, exit=${result.status}.`);

      if (failureClass === "transient" && attempt < transientRetryCount) {
        attempt += 1;
        console.warn(`[cycle] Retrying transient failure for '${agentName}' in ${transientRetryDelayMs} ms (attempt ${attempt + 1}/${transientRetryCount + 1}).`);
        sleepMs(transientRetryDelayMs);
        continue;
      }

      return {
        ok: false,
        agent: agentName,
        status: result.status,
        failureClass: failureClass || "hard"
      };
    }

    return {
      ok: false,
      agent: agentName,
      status: 1,
      failureClass: "hard"
    };
  }

  function validatePrerequisites() {
    if (!fs.existsSync(promptPath)) {
      throw new Error(`Prompt file not found: ${promptPath}`);
    }
    if (!fs.existsSync(fetchScriptPath)) {
      throw new Error(`Fetch script not found: ${fetchScriptPath}`);
    }
  }

  function safeReadText(filePath) {
    if (!fs.existsSync(filePath)) {
      return "";
    }

    return fs.readFileSync(filePath, "utf8");
  }

  function parseMarkdownBullets(markdownText) {
    return String(markdownText || "")
      .split(/\r?\n/)
      .filter((line) => line.startsWith("- "))
      .map((line) => line.slice(2).trim())
      .filter(Boolean);
  }

  function parseReviewStateEntries(markdownText, limit = 5) {
    const chunks = String(markdownText || "")
      .split(/^## /m)
      .map((chunk) => chunk.trim())
      .filter(Boolean);

    return chunks.slice(-limit).map((chunk) => {
      const lines = chunk.split(/\r?\n/).map((line) => line.trimEnd());
      const heading = lines[0] || "";
      const entry = {
        heading,
        action: "",
        literature: "",
        next_candidates: []
      };

      for (let i = 1; i < lines.length; i += 1) {
        const line = lines[i].trim();
        if (line.startsWith("Action:")) {
          entry.action = line.slice("Action:".length).trim();
          continue;
        }
        if (line.startsWith("Literature:")) {
          entry.literature = line.slice("Literature:".length).trim();
          continue;
        }
        if (line.startsWith("Next candidates:")) {
          const inline = line.slice("Next candidates:".length).trim();
          if (inline) {
            entry.next_candidates.push(inline);
          }

          for (let j = i + 1; j < lines.length; j += 1) {
            const candidateLine = lines[j].trim();
            if (!candidateLine.startsWith("- ")) {
              break;
            }
            entry.next_candidates.push(candidateLine.slice(2).trim());
            i = j;
          }
        }
      }

      return entry;
    });
  }

  function extractQuestionIds(csvText) {
    return String(csvText || "")
      .split(/\r?\n/)
      .slice(1)
      .map((line) => line.match(/^"?(\d+)/))
      .filter(Boolean)
      .map((match) => Number.parseInt(match[1], 10))
      .filter((value) => Number.isFinite(value));
  }

  function extractKnowledgeTopics(csvText) {
    const topicSet = new Set();
    const rowPattern = /^(?:"[^"]*"|[^,]*),(?:"([^"]*)"|([^,]*))/;

    for (const line of String(csvText || "").split(/\r?\n/).slice(1)) {
      const match = line.match(rowPattern);
      const topic = (match && (match[1] || match[2] || "")).trim();
      if (topic) {
        topicSet.add(topic);
      }
      if (topicSet.size >= 12) {
        break;
      }
    }

    return Array.from(topicSet);
  }

  function readDirtyPaths() {
    const tracked = spawnSync("git", ["-C", repoPath, "diff", "--name-only"], {
      cwd: repoPath,
      encoding: "utf8"
    });
    const untracked = spawnSync("git", ["-C", repoPath, "ls-files", "--others", "--exclude-standard"], {
      cwd: repoPath,
      encoding: "utf8"
    });

    return [tracked.stdout || "", untracked.stdout || ""]
      .join("\n")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean)
      .sort();
  }

  function buildCycleContext() {
    const questionsText = safeReadText(questionsPath);
    const knowledgeText = safeReadText(knowledgePath);
    const reviewStateText = safeReadText(reviewStatePath);
    const dailySummaryText = safeReadText(dailySummaryPath) || safeReadText(path.join(repoPath, "DAILY_LIT_CONTEXT.md"));
    const questionIds = extractQuestionIds(questionsText);
    const dailyBullets = parseMarkdownBullets(dailySummaryText).slice(0, 7);
    const reviewEntries = parseReviewStateEntries(reviewStateText, 5);

    return {
      generated_at: new Date().toISOString(),
      repo_path: repoPath,
      questions: {
        count: questionIds.length,
        latest_ids: questionIds.slice(-5)
      },
      knowledge_repository: {
        row_count: Math.max(0, knowledgeText.split(/\r?\n/).filter(Boolean).length - 1),
        sample_topics: extractKnowledgeTopics(knowledgeText)
      },
      daily_context: {
        bullets: dailyBullets
      },
      recent_cycles: reviewEntries,
      dirty_paths: readDirtyPaths().slice(0, 50),
      guidance: {
        primary_context_file: path.basename(cycleContextPath),
        keep_output_compact: true,
        avoid_dumping_file_contents: true
      }
    };
  }

  function writeCycleContext() {
    const context = buildCycleContext();
    fs.writeFileSync(cycleContextPath, JSON.stringify(context, null, 2) + "\n", "utf8");
  }

  function runDailyFetch() {
    try {
      const result = runCommand(process.execPath, [fetchScriptPath]);
      if (result.stdout) {
        emitLines(
          result.stdout
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter(Boolean)
        );
      }
      if (result.stderr) {
        emitLines(
          result.stderr
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter(Boolean),
          "warn"
        );
      }
      if ((result.status ?? 1) !== 0) {
        console.warn(`[cycle] Warning: daily fetch step exited with code ${result.status}. Continuing cycle.`);
      }
    } catch (err) {
      console.warn(`[cycle] Warning: daily fetch step failed (${err.message}). Continuing cycle.`);
    }
  }

  function runWithFallbackChain(defaultOrder) {
    validatePrerequisites();
    runDailyFetch();
    writeCycleContext();

    const promptText = fs.readFileSync(promptPath, "utf8");
    const providerOrder = reorderedProviderChain(defaultOrder);
    let lastFailureClass = null;
    let lastStatus = 1;

    console.log(`[cycle] Provider order for this cycle: ${providerOrder.join(" -> ")}.`);

    for (let i = 0; i < providerOrder.length; i += 1) {
      const agentName = providerOrder[i];
      const result = runAgentWithPolicy(agentName, promptText);

      if (result.ok) {
        writeProviderState({
          preferred_provider: agentName,
          last_success_provider: agentName,
          last_failure_class: null
        });
        return 0;
      }

      lastFailureClass = result.failureClass;
      lastStatus = result.status;

      if (result.failureClass === "quota") {
        const nextProvider = providerOrder[i + 1] || null;
        writeProviderState({
          preferred_provider: nextProvider,
          last_success_provider: readProviderState().last_success_provider,
          last_failure_class: "quota"
        });
        if (nextProvider) {
          console.warn(`[cycle] Quota hit on '${agentName}'. Next cycle will prefer '${nextProvider}'.`);
        }
      }
    }

    writeProviderState({
      preferred_provider: readProviderState().last_success_provider || defaultOrder[0] || null,
      last_success_provider: readProviderState().last_success_provider || null,
      last_failure_class: lastFailureClass
    });

    console.error(`[cycle] All agents failed in this cycle: ${providerOrder.join(" -> ")}.`);
    return lastStatus;
  }

  return {
    runWithFallbackChain,
    writeCycleContext
  };
}

module.exports = {
  createCycleRunner,
  _internals: {
    compareVersionParts,
    parseChatGptExtensionVersion,
    listInstalledCodexCandidates,
    resolveCodexCommand
  }
};

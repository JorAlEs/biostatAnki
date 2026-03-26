test_that("autonomous prompt protects runtime and control artifacts", {
  prompt_path <- test_path("..", "..", "claude_cycle_prompt.txt")
  prompt_text <- paste(readLines(prompt_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  expect_match(prompt_text, "one focused improvement", ignore.case = TRUE)
  expect_match(prompt_text, "NO CHANGE", fixed = TRUE)
  expect_match(prompt_text, "autonomous_cycle_context.json", fixed = TRUE)
  expect_match(prompt_text, "Do not print file contents", fixed = TRUE)
  expect_match(prompt_text, "daily_context/", fixed = TRUE)
  expect_match(prompt_text, "DAILY_LIT_CONTEXT.md", fixed = TRUE)
  expect_match(prompt_text, "AUTONOMOUS_REVIEW_STATE.md", fixed = TRUE)
  expect_match(prompt_text, "*.ps1", fixed = TRUE)
  expect_match(prompt_text, "*.log", fixed = TRUE)
})

test_that("autonomous loop keeps dirty-before exclusion in fallback staging", {
  loop_path <- test_path("..", "..", "biostatanki_autonomous_loop.ps1")
  loop_text <- paste(readLines(loop_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  expect_match(loop_text, "Pre-existing dirty package paths excluded from fallback", fixed = TRUE)
  expect_match(loop_text, "Where-Object \\{ \\$_ -notin \\$DirtyBefore \\}")
  expect_match(loop_text, "ConvertTo-Json -Compress", fixed = TRUE)
  expect_match(loop_text, "Get-Process -Id \\$PidToCheck", perl = TRUE)
})

test_that("cycle runners keep provider ordering and state persistence hooks", {
  main_runner <- paste(
    readLines(test_path("..", "..", "run_cycle.js"), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  claude_runner <- paste(
    readLines(test_path("..", "..", "run_cycle_claude.js"), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  common_runner <- paste(
    readLines(test_path("..", "..", "cycle_runner_common.js"), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )

  expect_match(main_runner, 'runWithFallbackChain\\(\\["codex", "claude", "ollama"\\]\\)')
  expect_match(claude_runner, 'runWithFallbackChain\\(\\["claude", "codex", "ollama"\\]\\)')
  expect_match(common_runner, "preferred_provider", fixed = TRUE)
  expect_match(common_runner, "last_success_provider", fixed = TRUE)
  expect_match(common_runner, "CLAUDECODE", fixed = TRUE)
  expect_match(common_runner, "resolveCodexCommand", fixed = TRUE)
  expect_match(common_runner, "autonomous_cycle_context.json", fixed = TRUE)
  expect_match(common_runner, "writeCycleContext", fixed = TRUE)
  expect_match(common_runner, "compactAgentOutput", fixed = TRUE)
  expect_match(common_runner, "Agent output compacted", fixed = TRUE)
})

test_that("node resolver prefers latest installed codex extension on Windows", {
  skip_if(.Platform$OS.type != "windows", "Windows-specific codex resolution test")
  skip_if(!nzchar(Sys.which("node")), "node is required for loop tooling tests")

  fake_home <- file.path(tempdir(), "biostatanki-codex-home")
  old_codex <- file.path(
    fake_home, ".vscode", "extensions",
    "openai.chatgpt-26.300.10000-win32-x64",
    "bin", "windows-x86_64", "codex.exe"
  )
  new_codex <- file.path(
    fake_home, ".vscode", "extensions",
    "openai.chatgpt-26.311.21342-win32-x64",
    "bin", "windows-x86_64", "codex.exe"
  )

  dir.create(dirname(old_codex), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(new_codex), recursive = TRUE, showWarnings = FALSE)
  writeBin(raw(), old_codex)
  writeBin(raw(), new_codex)

  script_path <- normalizePath(
    test_path("..", "..", "cycle_runner_common.js"),
    winslash = "/",
    mustWork = TRUE
  )
  node_script <- tempfile("codex-resolver-", fileext = ".js")
  writeLines(
    c(
      sprintf("const mod = require(%s);", dQuote(script_path)),
      "process.stdout.write(mod._internals.resolveCodexCommand());"
    ),
    node_script,
    useBytes = TRUE
  )
  on.exit(unlink(node_script), add = TRUE)

  old_userprofile <- Sys.getenv("USERPROFILE", unset = NA_character_)
  old_home <- Sys.getenv("HOME", unset = NA_character_)
  old_codex_cmd <- Sys.getenv("CODEX_CMD", unset = NA_character_)
  on.exit({
    if (is.na(old_userprofile)) Sys.unsetenv("USERPROFILE") else Sys.setenv(USERPROFILE = old_userprofile)
    if (is.na(old_home)) Sys.unsetenv("HOME") else Sys.setenv(HOME = old_home)
    if (is.na(old_codex_cmd)) Sys.unsetenv("CODEX_CMD") else Sys.setenv(CODEX_CMD = old_codex_cmd)
  }, add = TRUE)

  Sys.setenv(
    USERPROFILE = fake_home,
    HOME = fake_home,
    CODEX_CMD = ""
  )

  resolved <- system2(
    "node",
    node_script,
    stdout = TRUE,
    stderr = TRUE
  )

  expect_true(length(resolved) >= 1)
  expect_equal(
    normalizePath(resolved[[1]], winslash = "\\", mustWork = FALSE),
    normalizePath(new_codex, winslash = "\\", mustWork = TRUE)
  )
})

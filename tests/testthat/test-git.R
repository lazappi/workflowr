context("git")

# Setup ------------------------------------------------------------------------

# Load helper function local_no_gitconfig()
source("helpers.R", local = TRUE)

# Test get_committed_files and obtain_files_in_commit --------------------------

# Create temp Git directory
dir_git <- tempfile("test-get_committed_files-")
dir.create(dir_git)
dir_git <- workflowr:::absolute(dir_git)
on.exit(unlink(dir_git, recursive = TRUE, force = TRUE))
# Initialize Git repo
git2r::init(dir_git)
r <- git2r::repository(dir_git)
git2r::config(r, user.name = "Test Name", user.email = "test@email")

test_that("get_committed_files returns NA if no files have been committed", {
  expect_identical(workflowr:::get_committed_files(r), NA)
})

# Commit some files in root commit
f <- file.path(dir_git, c("a.txt", "b.txt"))
file.create(f)
git2r::add(r, f)
git2r::commit(r, message = "root commit")

test_that("get_committed_files works on root commit", {
  expected <- f
  actual <- workflowr:::get_committed_files(r)
  expect_identical(actual, expected)
})

test_that("obtain_files_in_commit works on root commit", {
  expected <- f
  actual <- workflowr:::obtain_files_in_commit(r, git2r::commits(r)[[1]])
  expect_identical(actual, expected)
})

# Commit more files
f2 <- file.path(dir_git, c("c.txt", "d.txt"))
file.create(f2)
git2r::add(r, f2)
git2r::commit(r, message = "another commit")

test_that("get_committed_files works on multiple commits", {
  expected <- c(f, f2)
  actual <- workflowr:::get_committed_files(r)
  expect_identical(actual, expected)
})

test_that("obtain_files_in_commit works on standard commit", {
  expected <- f2
  actual <- workflowr:::obtain_files_in_commit(r, git2r::commits(r)[[1]])
  expect_identical(actual, expected)
})

# Remove a file
git2r::rm_file(r, basename(f[1]))
git2r::commit(r, message = "remove a file")

test_that("get_committed_files stops reporting files after they are removed", {
  expected <- c(f[2], f2)
  actual <- workflowr:::get_committed_files(r)
  expect_identical(actual, expected)
})

test_that("obtain_files_in_commit reports a deleted file", {
  expected <- f[1]
  actual <- workflowr:::obtain_files_in_commit(r, git2r::commits(r)[[1]])
  expect_identical(actual, expected)
})

# Test check_git_config --------------------------------------------------------

test_that("check_git_config throws an error when user.name and user.email are not set", {

  skip_on_cran()

  # local_no_gitconfig() is defined in tests/testthat/helpers.R
  local_no_gitconfig("-workflowr")

  expect_error(workflowr:::check_git_config("."),
               "You must set your user.name and user.email for Git first")

  custom_message <- "fname"
  expect_error(workflowr:::check_git_config(".", custom_message = custom_message),
               custom_message)
})

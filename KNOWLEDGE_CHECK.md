# Lab 09: Knowledge check

**Answer each question below it, in your own words, in one to three sentences.** Replace the `...` below **Your answer:** with your text.

## 1. Credentials in the image?

Assume you want to share your image with others and make it publicly available on `ghcr.io`, so that anyone can pull it and run the analysis. A teammate suggests adding `COPY .aws /home/app/.aws` to the `Dockerfile`, so that nobody has to type `-v ~/.aws:/home/app/.aws:ro` any more. (This is a thought experiment: keep your own package private.)

**Your answer:** Give two reasons why this is a bad idea. Think of who could then read your credentials, and of what happens when your Learner Lab session ends.

First, anything copied into an image stays in its layers even if a later step deletes it, so on a public `ghcr.io` package anyone could pull the image and read `~/.aws/credentials`, then act as me in the Learner Lab account (S3 bucket, SSM parameter with the Atlas password). Second, Learner Lab credentials are temporary session credentials that expire when the session ends, so an image with them baked in would fail with `ExpiredToken` errors and need rebuilding every session. Mounting with `-v` avoids both problems because the container reads my current credentials from my computer at startup.

## 2. Where did the Atlas password come from?

In Step 4, you ran the analysis once with `-v ~/.aws:/home/app/.aws:ro` only, without the three `-e` options. The container still wrote to your Atlas cluster.

*Hint:* Read `get_atlas_settings()` in `src/book_analysis/analyze.py`.

**Your answer:** Explain, step by step, where the container found the Atlas settings in that run.

Without the `-e` options, `MONGODB_ATLAS_URL` wasn't set in the container, because a container doesn't inherit my terminal's environment variables, so `get_atlas_settings()` skipped its first branch. It then called AWS SSM with boto3, which found my credentials through the mounted `~/.aws` folder. It read and decrypted the `mongodb_credentials` parameter (JSON with the Atlas URL, user and password), and `connect()` used those to reach the cluster.

## 3. Same tag, different image

Run `docker images book-analysis`, and note the image ID of `book-analysis:0.1.0`. Then change the `description` in the `LABEL` of your `Dockerfile`, build again with the same command, `docker build -t book-analysis:0.1.0 .`, and run `docker images book-analysis` again.

**Your answer:** Paste the image ID from before and after the rebuild. Why is it a problem for someone who uses your image that `0.1.0` now names a different image, and what should you have done instead?

Before the rebuild the ID was `9fb3015317f2`, and after it was `8ffb8298b4c2`. Labels are part of the image configuration, so changing one changed the digest and the tag `0.1.0` moved to the new image. That's a problem because two people using `book-analysis:0.1.0` can end up with different software and no warning, which breaks reproducibility, so I should have bumped the version (e.g. `0.1.1`) and built under a new tag instead of rebuilding over a published one.

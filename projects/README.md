# Workflow project inventory

`repos.json` records Git repositories found under the Mac workflow directory.

Windows bootstrap clones missing repositories into:

```text
%USERPROFILE%\workflow
```

Bootstrap never overwrites an existing directory. Dirty Mac repositories remain the user's responsibility for patch or commit transfer.

Non-Git projects are not copied into this repository. The inventory records them only when the inventory script can identify them safely.

Keep active repositories out of OneDrive. Use Git remotes for synchronization.

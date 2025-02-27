# Repository Management Guide

This guide provides instructions on how to manage the FreeLIMS repository properly, ensuring it stays within GitHub size limits and maintains best practices.

## Repository Size Management

GitHub has size limits for repositories:
- Recommended maximum size: 1 GB
- Hard limit: 100 GB (but performance degrades significantly well before this)
- Individual file size limit: 100 MB

To keep the repository manageable:

1. **Never commit large binaries**: Use external storage or Git LFS for large files.
2. **Keep dependencies out**: Never commit `node_modules`, Python virtual environments, or other dependencies.
3. **Exclude build artifacts**: Build directories, compiled files, and temporary files should be excluded.
4. **Use proper branching**: Avoid long-lived branches with many commits ahead of main.

## What Should NOT Be in Version Control

The following should never be committed to the repository:

- **Dependencies**
  - `node_modules/` directory
  - Python virtual environments (`venv/`, `env/`, etc.)
  - Compiled libraries (`.so`, `.dll`, etc.)

- **Compiled/Generated Files**
  - `__pycache__/` directories
  - Python compiled files (`.pyc`, `.pyo`)
  - Build artifacts (`.o`, `.obj`, etc.)
  - Build directories (`build/`, `dist/`)
  - Bundled JavaScript/CSS (`bundle.js`, minified files)

- **Local Configuration**
  - `.env` files (containing secrets/credentials)
  - Local configuration files
  - User-specific IDE settings

- **Temporary Files**
  - Log files
  - Temporary files/directories
  - Cache directories (`.cache/`, etc.)
  - Swap files (`.swp`, etc.)

- **Large Data**
  - Database dumps
  - Large datasets
  - Media files (if large)
  - Backup files

## What SHOULD Be in Version Control

The following should be committed to the repository:

- **Source Code**
  - Python code (`.py`)
  - JavaScript/TypeScript (`.js`, `.jsx`, `.ts`, `.tsx`)
  - HTML/CSS/SCSS (`.html`, `.css`, `.scss`)
  - SQL schema files (small)

- **Configuration Files**
  - Package managers (`package.json`, `requirements.txt`)
  - Build configuration (`.babelrc`, `tsconfig.json`, etc.)
  - Example/template configuration (`.env.example`)
  - Git configuration (`.gitignore`, `.gitattributes`)

- **Documentation**
  - Documentation files (`.md`, `.rst`, etc.)
  - License files
  - README files
  - API specifications

- **Small Assets**
  - Icons, logos, and small images
  - Fonts (if small and properly licensed)

## Recovering from Repository Bloat

If your repository has become too large, you may need to perform a clean-up:

1. **Remove large files from history**:
   ```bash
   # Identify large files
   git rev-list --objects --all | grep -f <(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -10 | awk '{print $1}')

   # Use BFG Repo Cleaner or git-filter-repo to remove them
   # Example with BFG (after installing it):
   bfg --strip-blobs-bigger-than 1M
   ```

2. **Clean up and repack the repository**:
   ```bash
   git gc --aggressive --prune=now
   ```

## Preventing Future Issues

1. **Use the pre-commit hook**:
   ```bash
   cp scripts/git-hooks/pre-commit .git/hooks/
   chmod +x .git/hooks/pre-commit
   ```

2. **Consider Git LFS** for binary/large files:
   ```bash
   # Install Git LFS
   git lfs install
   
   # Track files by pattern
   git lfs track "*.png"
   ```

3. **Check what's being committed** before pushing:
   ```bash
   # See what changes are staged
   git status
   
   # See exactly what's being committed
   git diff --staged
   ```

## Additional Resources

- [Git LFS Documentation](https://git-lfs.github.com/)
- [GitHub's documentation on repository size limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) 
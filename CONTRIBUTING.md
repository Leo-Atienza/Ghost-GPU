# Contributing to GhostGPU

Thank you for your interest in contributing to GhostGPU! 🎉

We welcome contributions of all kinds — bug fixes, new features, documentation improvements, and more.

## How to Contribute

### Reporting Bugs

1. Search [existing issues](https://github.com/Leo-Atienza/Ghost-GPU/issues) to avoid duplicates.
2. Open a new issue using the **Bug Report** template.
3. Include as much detail as possible: OS version, ROCm version, hardware, and reproduction steps.

### Suggesting Features

1. Search [existing issues](https://github.com/Leo-Atienza/Ghost-GPU/issues) to see if it's already requested.
2. Open a new issue using the **Feature Request** template.
3. Describe the problem you're solving and why this feature would be valuable.

### Submitting Code

1. **Fork** the repository and clone your fork locally.
2. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes, following the code style of the project.
4. Test your changes on real hardware if possible.
5. **Commit** with a clear, descriptive message:
   ```bash
   git commit -m "feat: add mDNS autodiscovery for ghostgpu.local"
   ```
6. **Push** your branch and open a Pull Request against `main`.
7. Fill in the PR template thoroughly.

## Code Style

- **Shell scripts**: Follow POSIX-compatible bash. Use `shellcheck` to lint scripts.
- **Markdown**: Keep line length reasonable; use fenced code blocks with language tags.
- **Commit messages**: Prefer conventional commits (`feat:`, `fix:`, `docs:`, `chore:`).

## Development Setup

```bash
git clone https://github.com/Leo-Atienza/Ghost-GPU.git
cd Ghost-GPU
# Install shellcheck for script linting
sudo apt install shellcheck
# Lint all scripts
shellcheck scripts/*.sh configs/*.sh
```

## Pull Request Checklist

Before submitting a PR, please ensure:

- [ ] I have tested my changes (on hardware or in simulation where possible)
- [ ] Shell scripts pass `shellcheck` with no errors
- [ ] Documentation is updated if required
- [ ] The PR description clearly explains the change and motivation
- [ ] I have read and agree to the [Code of Conduct](CODE_OF_CONDUCT.md)

## Questions?

Open a [Discussion](https://github.com/Leo-Atienza/Ghost-GPU/discussions) or an issue — we're happy to help!

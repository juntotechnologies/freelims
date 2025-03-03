# FreeLIMS Development Workflow

This document outlines the development and deployment workflow for FreeLIMS.

## Branch Structure

FreeLIMS uses a Git Flow-inspired workflow with two main branches:

- **`main`**: Production-ready code that runs in the production environment
- **`develop`**: Latest development code that runs in the development environment

## Development Process

### Making Changes

1. **Start from `develop` branch**
   ```bash
   git checkout develop
   git pull origin develop  # Make sure you have the latest changes
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
   
3. **Make changes and test in the development environment**
   The development environment runs on:
   - API: http://localhost:8001
   - Frontend: http://localhost:3001

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

5. **Push your feature branch**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Merge to `develop`**
   ```bash
   git checkout develop
   git merge feature/your-feature-name
   git push origin develop
   ```
   
   Alternatively, create a pull request on GitHub from your feature branch to `develop`

7. **Delete your feature branch (optional)**
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

### Deploying to Production

When development changes are tested and ready for production:

1. **Merge to `main`**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```
   
   Alternatively, create a pull request on GitHub from `develop` to `main`

## Continuous Integration/Deployment

GitHub Actions is configured to automatically:

1. On pushes to `develop`:
   - Deploy to the development environment (ports 8001/3001)
   - Run migrations on the development database

2. On pushes to `main`:
   - Deploy to the production environment (ports 8002/3002)
   - Run migrations on the production database

## Environment Access

- **Development Environment**:
  - API: http://localhost:8001
  - Frontend: http://localhost:3001
  
- **Production Environment**:
  - API: http://localhost:8002
  - Frontend: http://localhost:3002

## Best Practices

1. **Always work in feature branches** off the `develop` branch
2. **Test thoroughly** in the development environment before merging to `develop`
3. **Only merge to `main` when code is production-ready**
4. **Regularly pull changes** from the remote repository to stay up-to-date
5. **Review the GitHub Actions logs** to ensure deployments are successful 
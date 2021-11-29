# DevOps Engineer - technical interview submission

## Tasks Breakdown
The requirement is broken down into below tasks
[X] Pull sorce code locally to build, run and verify.
[X] Register for an account with Accuweather, get the API key to configure the app.
[X] Update the app with API key locally to test it. 
[X] Create CI pipelines using Github actions.
    [X] Build app and run any unit tests available on every push to main branch. 
    [X] Store build artifacts
[X] Create a webapp to manually publish and check whether the app works fine. This is to find out any issues we may find during deployment.
[ ] Infrastructure as code using Terraform 
   [X] Generate Azure creds for Terraform to provision the infrastruture - Add these as secrets to Github repository.
   [X] Create Azure storage account to persist the terraform state of the infrastruture
   [X] Locally create a basic tf files and integrate it with the pipeline.
   [ ] Store Azure Creds as secrets in github repo settings.
   [ ] Store Weather API as secrets
   [ ] As part of IAC create keyvault to load settings to webapp. 
[X] Check code for security vulnerabilities
    [X] Use snyk to scan the code.
    [X] Publish the result to github.
[X] Continous deployment
    [X] After successful build, vulnerability scan and IAC stage deploy the app
[ ] DevOps Solution architecture.
[ ] Security consideration.
[ ] Automated testing for quality gate. 
[ ] App Versioning


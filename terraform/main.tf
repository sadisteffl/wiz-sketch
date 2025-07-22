
     terraform {
       backend "remote" {
         # The name of your Terraform Cloud organization.
         organization = "wiz-sketch"

         # The name of the Terraform Cloud workspace to store Terraform state files in.
         workspaces {
           name = "wiz-sketch"
         }
       }
    }



# 3. Reference the GitHub secret in step using the `hashicorp/setup-terraform` GitHub Action.
#   Example:
#     - name: Setup Terraform
#       uses: hashicorp/setup-terraform@v1
#       with:
#         cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

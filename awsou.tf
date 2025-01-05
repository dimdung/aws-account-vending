# OUs are manually created (not created by Terraform)  
# This can be used to re-create OU structure from Terraform

## AWS Organization 
data "aws_orginizations_organization" "cqpocs"{}

## Below are the OU
resource "aws_organizations_organizational_unit" "helix" {
   name      = "HELIX"
   parent_id = aws_organizations_organization.example.roots[0].id
 }

 resource "aws_organizations_organizational_unit" "workloads" {
   name      = "Workloads"
   parent_id = aws_organizations_organizational_unit.helix.id
 }

 resource "aws_organizations_organizational_unit" "platform" {
   name      = "Platform"
   parent_id = aws_organizations_organizational_unit.helix.id
 }

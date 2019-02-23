# AWS Short Intro Demonstration For Tieto Specialists  <!-- omit in toc -->


# Table of Contents  <!-- omit in toc -->
- [Introduction](#introduction)
- [AWS Solution](#aws-solution)
- [Terraform Code](#terraform-code)
- [Terraform File Types](#terraform-file-types)
- [Terraform Env and Modules](#terraform-env-and-modules)
  - [Env Parameters](#env-parameters)
  - [Env-def Module](#env-def-module)
  - [Resource-groups Module](#resource-groups-module)
  - [Vpc Module](#vpc-module)
  - [Ec2 Module](#ec2-module)
- [AWS Tags](#aws-tags)
- [Terraform Backend](#terraform-backend)
- [Demonstration Manuscript](#demonstration-manuscript)
- [Demonstration Manuscript for Windows Users](#demonstration-manuscript-for-windows-users)
- [Suggestions How to Continue this Demonstration](#suggestions-how-to-continue-this-demonstration)


# Introduction

This demonstration can be used in training new cloud specialists who don't need to have any prior knowledge of AWS but who want to start working on AWS projects and building their AWS competence.

This project demonstrates basic aspects how to create cloud infrastructure using code. The actual infra is very simple: just one EC2 instance. We create a virtual private cloud ([vpc](https://aws.amazon.com/vpc/) and an application subnet into which we create the [EC2](https://aws.amazon.com/ec2/). There is also one [security group](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) in the application subnet that allows inbound traffic only using ssh port 22. The infra creates private/public keys and installs the public key to the EC2 instance - you get the private key for connecting to the EC2 instance once you have deployed the infra.

I tried to keep this demonstration as simple as possible. The main purpose is not to provide an example how to create a cloud system (e.g. not recommending EC2s over containers) but to provide a very simple example of infrastructure code and tooling related creating the infra. I have provided some suggestions how to continue this demonstration at the end of this document - you can also send me email to my corporate email and suggest what kind of AWS or AWS POCs you need in your AS team - I can help you to create the POCs for your customer meetings.

NOTE: There is an equivalent Azure demonstration - [azure-intro-demo](https://github.com/tieto-pc/azure-intro-demo) - compare the terraform code between these AWS and Azure infra implementations and you realize how similar they are.


# AWS Solution

The diagram below depicts the main services / components of the solution.

![AWS Intro Demo Architecture](docs/aws-intro-demo.png?raw=true "AWS Intro Demo Architecture")

So, the system is extremely simple (for demonstration purposes): Just one application subnet and one EC2 instance doing nothing in the subnet. Subnet security group which allows only ssh traffic to the EC2 instance. 


# Terraform Code

I am using [Terraform](https://www.terraform.io/) as an [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) (IaC) tool. Terraform is very much used both in the AWS and Azure sides and one of its strenghts compared to cloud native tools (AWS / [CloudFormation](https://aws.amazon.com/cloudformation) and Azure / [ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates)) is that you can use Terraform with many cloud providers, you have to learn just one infra language and syntax, and Terraform language (hcl) is pretty powerful and clear. When deciding the actual infra code tool you should consult the customer if there is some tooling already decided. Otherwise you should evaluate CloudFormation and Terraform and then decide which one is more appropriate for the needs of your AWS cloud project.

If you are new to infrastructure as code (IaC) and terraform specifically let's explain the high level structure of the terraform code first. Project's terraform code is hosted in [terraform](terraform) folder.

It is a cloud best practice that you should modularize your infra code and also modularize it so that you can create many different (exact or as exact as you like) copies of your infra  re-using the infra modules. I use a common practice to organize terraform code in three levels:

1. **Environment parameters**. In [envs](terraform/envs) folder we host the various environments. In this demo we have only the dev environment, but this folder could have similar env parameterizations for qa, perf, prod environments etc. 
2. **Environment definition**. In [env-def](terraform/modules/env-def) folder we define the modules that will be used in every environment. The environments inject the environment specific parameters to the env-def module which then creates the actual infra using those parameters by calling various infra modules and forwarding environment parameters to the infra modules.
3. **Modules**. In [modules](terraform/modules) folder we have the modules that are used by environment definition (env-def, a terraform module itself also). There are modules for the main services used in this demonstration: [vpc](https://aws.amazon.com/vpc/) and [EC2](https://aws.amazon.com/ec2/), and [resource groups](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/what-are-resource-groups.html) which gather the infra resources into views regarding the resource group's tag.


# Terraform File Types

There are basically three types of Terraform files in this demonstration:
- The actual infra definition file with the same name as the module folder.
- Variables file. You use variables file to declare variables that are used in that specific module.
- Outputs file. You can use outputs file as a mechanism to print certain interesting infra values. Outputs are also a mechanism to transfer infra information from one module to another.

I encourage the reader to read more about Terraform in [Terraform documentation](https://www.terraform.io/docs/index.html).

# Terraform Env and Modules

In this chapter we walk through the terraform modules a bit deeper.

## Env Parameters

You can find all parameters related to dev env in file [dev.tf](terraform/envs/dev/dev.tf). Open the file.

This file starts with the terraform backend - more about it later in the "Terraform Backend" chapter. What you now need to know is that you need to create a S3 bucket and DynamoDB table to store the terraform state.

After the backend configuration we have the terraform locals definition - these are provided for this context and we use them to inject the parameter values to the env-def module which follows right after the locals definition.

After locals there is the provider definition (aws apparently in the case of this AWS demonstration). 

Finally we inject the dev env parameters to the env-def module.


## Env-def Module

All right! In the previous file we injected dev env parameters to the [env-def.tf](terraform/modules/env-def/env-def.tf) module. Open this file now.

You see that this module defines three other modules. The idea is that this env-def - Environment definition - can be re-used by all envs, like ```dev```, ```qa```, ```perf``` and ```prod``` etc - they all just inject their env specific parameters to the same environment definition which gives a more detailed definition what kind of modules there are in this infrastructure.

So, this environment defition defines three modules: resource groups, virtual private cloud (vpc) and an EC2 instance. Let's walk through those modules next.


## Resource-groups Module

The [resource-groups](terraform/modules/resource-groups) just defines the AWS resource group views for resources regarding some tag.


## Vpc Module

The [vpc](https://aws.amazon.com/vpc/) definition is a bit longer. First it defines a virtual private cloud (vpc). We inject a [cidr address space](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) for the vpc. All our resources will be using this address space. 

We are going to define a [public subnet](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario1.html) and in the AWS side that means two things: 1. We need to define an [internet gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html) and 2. a [route table](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html) for forwarding the traffic to the internet gateway. There is also the actual subnet definition and the association with the route table for this subnet. 

Finally there is the [security group](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html) definition in which we associate this sg to the vpc. We have only rule in this sg - the only inbound traffic that we allow is ssh (port 22).


## Ec2 Module

The [EC2](https://aws.amazon.com/ec2/) module is a also a bit more complex. But let's not be intimidated - let's see what kind of bits and pieces there are in this module. 

We first create the ssh keys. I later realized that there is some bash inline scripting here - most possibly won't be working if you run terraform in a Windows box (I must test this myself and make this part a bit simpler e.g. injecting the ssh public key manually here). Then we create the key pair that will be stored in AWS (you can see it in the AWS Portal in the EC2 view / Key pairs). 

It is a best practice to run an EC2 instance with so called [instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) - for this purpose we create an [IAM role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) and instance profile which uses the IAM role. 

We also create an [elastic ip](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html).

Finally we have all the bits and pieces created and we are ready for the actual [EC2 instance](https://aws.amazon.com/ec2) definition in which we inject all the resources we earlier created in this module.


# AWS Tags

In all main resources (that support tagging) I have added some [aws tags](https://docs.aws.amazon.com/aws-technical-content/latest/cost-optimization-laying-the-foundation/tagging.html). 

- Name: "intro-demo-dev-vpc" - this is the name of the resource.
- Env: "dev" - this is the env (e.g. dev, qa, perf, prod...)
- Environment: "intro-demo-dev" - this is the specific environment for a specific infra, i.e. we are running dev for intro-demo (I realized now that in future demos I might change this tag to "Deployment" not to mix Environment and Env tags).
- Prefix: "intro-demo" - this is the infra without the env postfix.
- Location: "westeurope" - AWS location.
Terraform: "true" (fixed)


If you figure out some consistent tagging system it is easier for you to find resources using tags. Examples:

- Env = "dev" => All resources in all projects which have deployed as "dev".
- Prefix = "intro-demo" => All intro-demos resources in all envs (dev, perf, qa, prod...)
- Environment = "intro-demo-dev" => The resources of a specific terraform deployment (since each demo has dedicated deployments for all envs)


# Terraform Backend

In a small project like this in which you are working alone you don't actually need a Terraform backend but I have used it in this demonstration to make a more realistic demonstration. You should use Terraform backend in any project that has more than one developer. The reason for using a Terraform backend is to store and lock your terraform state file so that many developers cannot concurrently make conflicting changes to the infrastructure.

You can manually create a S3 bucket and a DynamoDB table to store your terraform backend. I could have created a bash script for creating these entities but I use myself the same S3 bucket and the same DynamoDB table for all my projects so this is basically a one-time task. So, create a S3 bucket and a DynamoDB table. For DynamoDB table you need to name the Partition key as "LockID" (type String). Then configure the S3 bucket name and DynamoDB table name in [dev.tf](terraform/envs/dev/dev.tf).

Then create yourself AWS access and secret keys. Go to AWS portal / IAM / YOUR-USER-ACCOUNT. You can find there "Security credentials" section => create the keys here. Then you should create an AWS profile to the configuration section in your ~/.aws/credentials. Add a section for your AWS account and copy-paste the keys there, e.g.:

```text
[my-aws-profile]
aws_access_key_id = YOUR-ACCESS-KEY
aws_secret_access_key = YOUR-SECRET-KEY
```

Whenever you give terraform commands or use aws cli you should give the AWS profile environment variable with the command, e.g.:

```bash
AWS_PROFILE=MY-PROFILE terraform init
```

NOTE: If you need to delete the backend completely, then delete these:
- the ```.terraform``` folder in your terraform/envs/dev folder
- the terraform state file in your S3 bucket (do not delete the bucket - just the file)
- the related items in the DynamoDB Lock table



# Demonstration Manuscript

NOTE: These instructions are for Linux (most probably should work for Mac as well). Windows instructions are in the next chapter.

Let's finally give detailed demonstration manuscript how you are able to deploy the infra of this demonstration to your AWS account. You need an AWS account for this demonstration. You can order a private AWS account or you can contact your line manager if there is an AWS development account in your unit that you can use for self-study purposes to learn how to use AWS. **NOTE**: Watch for costs! Always finally destroy your infrastructure once you are ready (never leave any resources to run indefinitely in your AWS account to generate costs).

1. Install [Terraform](https://www.terraform.io/). You might also like to add Terraform support for your favorite editor (e.g. there is a Terraform extension for VS Code).
2. Install [AWS command line interface](https://aws.amazon.com/cli).
3. Clone this project: git clone https://github.com/tieto-pc/aws-intro-demo.git
4. Configure the terraform backend as instructed in chapter "Terraform Backend". Create AWS credentials file as instructed in the same chapter.
5. Open console in [dev](terraform/envs/dev) folder. Give commands
   1. ```terraform init``` => Initializes the Terraform backend state.
   2. ```terraform get``` => Gets the terraform modules of this project.
   3. ```terraform plan``` => Gives the plan regarding the changes needed to make to your infra. **NOTE**: always read the plan carefully!
   4. ```terraform apply``` => Creates the delta between the current state in the infrastructure and your new state definition in the Terraform configuration files.
6. Open AWS Portal and browse different views to see what entities were created:
   1. Resource Groups => Saved groups => Click some resource group
   2. Click the vpc. Browse subnets etc.
   3. Click EC2 instance => Browse different information regarding the EC2.
7. Test to get ssh connection to the EC2 instance:
   1. terraform output -module=env-def.ec2 => You get the public ip of the EC2. (If you didn't get an ip, run terraform apply again - terraform didn't get the ip to state file in the first round.)
   2. Open another terminal in project root folder.
   3. ssh -i terraform/modules/ec2/.ssh/vm_id_rsa ubuntu@IP-NUMBER-HERE
8. Finally destroy the infra using ```terraform destroy``` command. Check manually also using Portal that terraform destroyed all resources. **NOTE**: It is utterly important that you always destroy your infrastructure when you don't need it anymore - otherwise the infra will generate costs to you or to your unit.


# Demonstration Manuscript for Windows Users

1. Install [Terraform](https://www.terraform.io/). 
2. Install [AWS command line interface](https://aws.amazon.com/cli).
3. Clone this project: git clone https://github.com/tieto-pc/aws-intro-demo.git
4. Configure the terraform backend as instructed in chapter "Terraform Backend". Create AWS credentials file as instructed in the same chapter.
5. Open Windows command prompt. Give command: set AWS_PROFILE=YOUR-AWS-PROFILE-HERE
6. Change the ssh key creation to use Windows style: [dev.tf](terraform/envs/dev/dev.tf) change the value of local variable ```my_workstation_is_linux``` from default value "1" (meaning your workstation is linux/mac) to value "0" (meaning your workstation is windows). This is a bit of a hack but needed for storing the private ssh key automatically to your workstation's local disk to make things easier in this demo (no need to create the ssh keys manually and use it in the infra code).
7. Open console in [dev](terraform/envs/dev) folder. Give commands
   1. ```terraform init``` => Initializes the Terraform backend state.
   2. ```terraform get``` => Gets the terraform modules of this project.
   3. ```terraform plan``` => Gives the plan regarding the changes needed to make to your infra. **NOTE**: always read the plan carefully!
   4. ```terraform apply``` => Creates the delta between the current state in the infrastructure and your new state definition in the Terraform configuration files.
8. Open AWS Portal and browse different views to see what entities were created:
   1. Resource Groups => Saved groups => Click some resource group
   2. Click the vpc. Browse subnets etc.
   3. Click EC2 instance => Browse different information regarding the EC2.
9. Test to get ssh connection to the EC2 instance:
   1. terraform output -module=env-def.ec2 => You get the public ip of the EC2. (If you didn't get an ip, run terraform apply again - terraform didn't get the ip to state file in the first round.)
   2. Open another terminal in project root folder (powershell).
   3. ssh -i terraform/modules/ec2/.ssh/vm_id_rsa ubuntu@IP-NUMBER-HERE (**TODO**: Here I need some help. I'm not a Windows user so I have no idea how to set the file permissions regarding the private ssh key. Also when trying with ssh client in Windows the ssh client complained about wrong key format - I copy-pasted the content of the ssh key to my Linux and the key worked there just fine. So, I'd appreciate if some Windows user writes this section how to try ssh connection to the EC2 instance.)
10. Finally destroy the infra using ```terraform destroy``` command. Check manually also using Portal that terraform destroyed all resources. **NOTE**: It is utterly important that you always destroy your infrastructure when you don't need it anymore - otherwise the infra will generate costs to you or to your unit.
 
**NOTE**: Currently there are two issues with storing the private key in a Windows box: In  [ec2.tf](terraform/modules/ec2/ec2.tf) => "vm_save_ssh_key_windows":

1. We should add a powershell command here to make the private key visible only for the current user (or ssh client does not allow using it (as I did in the Linux side)). I couldn't figure out how to do it using some Windows native command line tool (like icalc), so I used Git Bash in Windows and gave command: chmod go-rwx vm_id_rsa
2. The format of the key file should be stored so that the user shouldn't need to use some editor to fix the encoding. Sami Huhtiniemi kindly provided a workaround for the encoding: Converting SSH-file to Windows-format => Open file vm_id_rsa -file (located inside terraform\envs\dev\.terraform\modules…\..ssh\ using [Notepad++](https://notepad-plus-plus.org/) & convert to UTF-8. I.e. we should be able to store the file in UTF-8 in the first place.

If you give me powershell commands that you have validated yourself deploying this demonstration, and I try to deploy the demonstration with your patch and if the patch really works, you will have an honorary mention in this document providing the Windows wizardry to fix the problem. :-) 



# Suggestions How to Continue this Demonstration

We could add e.g. an autoscaling group and a load balancer to this demonstration but let's keep this demonstration as short as possible so that it can be used as an AWS introduction demonstration. If there are some improvement suggestions that our AS developers would like to see in this demonstration let's create other small demonstrations for those purposes, e.g.:
- Create a custom Linux image that has the Java app baked in.
- An autoscaling group for EC2s (with CRM app baked in) + a load balancer.
- Logs to CloudWatch.
- Use container instead of EC2.
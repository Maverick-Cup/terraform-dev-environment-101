# terraform-dev-environment-101
Learn Terraform with Azure by Building a Dev Environment – Full Course for Beginners Credits

1. Remeber to change the Location to one which is near to you before deployment and change the path where applicable, if not set to home ~/ .
2. In the windows-ssh-script.tpl file the path in the first line needs a "" to resolve the error.
3. Generally in couple of attempts the Dynamic ip is generated but if it doesn't then change the value from "Dynamic" to "Static" to get the allocated IPs faster.
4. Pause a bit before you validate docker --version , provisioning takes sometime.
5. If you stop the VM then remember to click on the "retain the IP" else it will be lost.
6. Refer for details in the video help - https://youtu.be/V53AHWun17s
   6.1 - At 56 minute the docker implementation is missing - just copy these content from the link below by matching the content if you're eager to understand each line.
   https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine 

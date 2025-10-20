This Terraform code provisions a complete and secure network foundation in AWS, known as a **Virtual Private Cloud (VPC)**.  

The setup creates a classic, multi-tier architecture with separate layers for public access, application logic, and data, ensuring a high level of security and availability.

***

### The Network Layout

* **`aws_vpc`**: This is the main resource, creating a logically isolated network space for your resources with an IP address range of `10.0.0.0/16`.
* **`aws_subnet`**: The VPC is carved into smaller networks called subnets:
    * **Private Subnets**: Two private subnets (`cc-private-subnet-a` and `cc-private-subnet-b`) are created in different Availability Zones. These are for backend resources like your application servers and databases that should **not** be directly accessible from the internet.
    * **Public Subnet**: One public subnet (`cc-public-subnet-a`) is created to host resources that need to face the internet, like a load balancer or the NAT Gateway itself.



***

### Internet Connectivity 🌐

* **`aws_internet_gateway` (IGW)**: This acts as the main door to the internet for your VPC. It's attached to the VPC to allow resources in the **public subnet** to communicate directly with the internet.
* **`aws_nat_gateway` (NAT GW)**: This is a critical component for security. It allows resources in the **private subnets** to initiate outbound connections to the internet (e.g., to download software updates or call third-party APIs) without allowing the internet to initiate connections back in. It uses an **Elastic IP** (`aws_eip`) to have a static public IP address.

***

### Traffic Routing 🗺️

Route tables act like a GPS for your network traffic, telling it where to go.

* **Public Route Table (`cc_public_rt`)**: This table is associated with the public subnet. It has a route (`0.0.0.0/0`) that sends all internet-bound traffic directly to the **Internet Gateway**.
* **Private Route Table**: The main route table is used for the private subnets. It has a route (`0.0.0.0/0`) that sends all internet-bound traffic to the **NAT Gateway**, enabling secure outbound access.

***

### Firewall Rules 🛡️

Security Groups are stateful firewalls that control traffic to and from your resources. This code creates a chain of trust between layers.

* **API Security Group (`cc-api-sg`)**: This is the outermost layer, allowing inbound web traffic (HTTP on port 80, HTTPS on 443) from anywhere on the internet. This would be attached to a load balancer or API Gateway.
* **Compute Security Group (`cc-compute-sg`)**: This is for your application servers. It only allows inbound traffic on port `8080` and **only** from resources within the API security group. The public internet cannot reach this layer directly.
* **RDS Security Group (`cc-rds-sg`)**: This is the most secure layer, for your database. It only allows inbound traffic on the database port `3306` and **only** from resources within the compute security group.

***

### Database and Outputs

* **`aws_db_subnet_group`**: This is a helper resource required by Amazon RDS. It tells your database which of the private subnets it can be deployed into, enabling high availability across multiple Availability Zones.
* **`output` blocks**: These export the unique IDs of the created resources (like the VPC ID and security group IDs) so they can be easily used by other Terraform configurations that will deploy applications onto this network.
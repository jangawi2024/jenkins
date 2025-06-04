provider "aws" {
    region = "us-east-1"
}

resource "aws_subnet" "new_subnet" {
    vpc_id            = "vpc-0b7663962ba7082cb" # Use the correct VPC ID
    cidr_block        = "172.31.0.0/16" # Substitua pelo bloco CIDR desejado
    availability_zone = "us-east-1a" # Substitua pela zona de disponibilidade desejada

    tags = {
        Name = "NewSubnet"
    }
}

resource "aws_security_group" "jenkins_sg" {
    name        = "jenkins_sg"
    description = "Security group para Jenkins"
    
    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # **Altere para um IP específico em produção**
    }
}

resource "aws_instance" "jenkins_server" {
    ami           = "ami-02457590d33d576c3" # Substitua pelo AMI correto
    instance_type = "t2.medium"
    key_name      = "lab001" # Substitua pela sua chave SSH
    subnet_id              = aws_subnet.new_subnet.id
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

    tags = {
        Name = "JenkinsServer"
    }

    user_data = <<-EOF
                            #!/bin/bash
                            sudo apt update -y
                            sudo apt install -y docker.io
                            sudo systemctl enable docker
                            sudo systemctl start docker

                            # Instalar Docker Compose
                            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                            sudo chmod +x /usr/local/bin/docker-compose

                            # Clonar repositório com Dockerfile e docker-compose.yml
                            git clone https://github.com/seu-repo/jenkins-docker /home/ubuntu/jenkins
                            cd /home/ubuntu/jenkins
                            sudo docker-compose up -d
                            EOF
}

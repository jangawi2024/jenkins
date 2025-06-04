provider "aws" {
    region = "us-east-1"
}

resource "aws_route_table" "public_route_table" {
    vpc_id = "vpc-0b7663962ba7082cb"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "igw-0ce2236c780cebf2a"
    }

    tags = {
        Name = "PublicRouteTable"
    }
}

resource "aws_route_table_association" "subnet_association" {
    subnet_id      = aws_subnet.new_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "new_subnet" {
    vpc_id                  = "vpc-0b7663962ba7082cb"
    cidr_block              = "172.31.0.0/16"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "NewSubnet"
    }
}

resource "aws_subnet" "new_subnet_2" {
    vpc_id                  = "vpc-0b7663962ba7082cb"
    cidr_block              = "172.32.0.0/16" # Alterado para evitar conflito
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "NewSubnet2"
    }
}

resource "aws_security_group" "jenkins_sg" {
    name        = "jenkins_sg"
    description = "Security group para Jenkins"

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "jenkins_server" {
    ami           = "ami-02457590d33d576c3"
    instance_type = "t2.medium"
    key_name      = "lab001"
    subnet_id              = aws_subnet.new_subnet.id
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

    tags = {
        Name = "JenkinsServer"
    }

    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y docker
        sudo systemctl enable docker
        sudo systemctl start docker

        # Instalar Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        # Montar o disco persistente
        sudo mkdir -p /mnt/data
        sudo file_system=$(lsblk -o FSTYPE -n /dev/xvdf)
        if [ -z "$file_system" ]; then
            sudo mkfs.ext4 /dev/xvdf
        fi
        sudo mount /dev/xvdf /mnt/data
        sudo chmod 777 /mnt/data/

        # Adicionar ao fstab para montagem automática
        echo "/dev/xvdf /mnt/data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

        # # Verificar se a pasta jenkins já existe antes de clonar
        # if [ ! -d "/mnt/data/jenkins" ]; then
        #     sudo yum install -y git
        #     git clone https://github.com/jangawi2024/jenkins.git /mnt/data/jenkins
        # else
        #     echo "A pasta /mnt/data/jenkins já existe. Não será sobrescrita."
        # fi

        cd /mnt/data/jenkins

        sudo chmod 777 /mnt/data/jenkins
        sudo chown 1000:1000 /mnt/data/jenkins # Define o dono como o usuário Jenkins (UID 1000)

        # Usar o disco para Jenkins
        sudo docker-compose up -d
    EOF
}

resource "aws_volume_attachment" "jenkins_volume_attachment" {
    device_name = "/dev/xvdf" # Substitua pelo dispositivo correto
    volume_id   = "vol-058aa6fa82c54ac95" # ID do disco existente
    instance_id = aws_instance.jenkins_server.id
}

resource "aws_lb" "jenkins_alb" {
    name               = "jenkins-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.jenkins_sg.id]
    subnets            = [aws_subnet.new_subnet.id, aws_subnet.new_subnet_2.id] # Incluindo ambas as subnets

    tags = {
        Name = "JenkinsALB"
    }
}
 

resource "aws_lb_target_group" "jenkins_tg" {
    name        = "jenkins-tg"
    port        = 8080
    protocol    = "HTTP"
    vpc_id      = "vpc-0b7663962ba7082cb"
    target_type = "instance"

    health_check {
        path                = "/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }

    tags = {
        Name = "JenkinsTargetGroup"
    }
}

resource "aws_lb_listener" "jenkins_listener" {
    load_balancer_arn = aws_lb.jenkins_alb.arn
    port              = 8080
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.jenkins_tg.arn
    }
}

resource "aws_lb_target_group_attachment" "jenkins_attachment" {
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
    target_id        = aws_instance.jenkins_server.id
    port             = 80
}

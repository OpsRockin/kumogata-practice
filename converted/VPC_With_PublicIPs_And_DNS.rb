AWSTemplateFormatVersion "2010-09-09"
Description "AWS CloudFormation Sample Template VPC_with_PublicIPs_And_DNS.template: Sample template showing how to create a multi-tier VPC with multiple subnets DNS support. The instances have automatic public IP addresses assigned. The first subnet is public and contains a NAT device for internet access from the private subnet and a bastion host to allow SSH access to the hosts in the private subnet. You will be billed for the AWS resources used if you create a stack from this template."
Parameters do
  KeyName do
    Description "Name of an existing EC2 KeyPair to enable SSH access to the bastion host"
    Type "String"
    MinLength 1
    MaxLength 64
    AllowedPattern "[-_ a-zA-Z0-9]*"
    ConstraintDescription "can contain only alphanumeric characters, spaces, dashes and underscores."
  end
  SSHFrom do
    Description "Lockdown SSH access to the bastion host (default can be accessed from anywhere)"
    Type "String"
    MinLength 9
    MaxLength 18
    Default "0.0.0.0/0"
    AllowedPattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    ConstraintDescription "must be a valid CIDR range of the form x.x.x.x/x."
  end
  EC2InstanceType do
    Description "EC2 instance type"
    Type "String"
    Default "m1.small"
    AllowedValues "t1.micro", "m1.small", "m1.medium", "m1.large", "m1.xlarge", "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "c1.medium", "c1.xlarge", "cc1.4xlarge", "cc2.8xlarge", "cg1.4xlarge"
    ConstraintDescription "must be a valid EC2 instance type."
  end
end
Mappings do
  AWSInstanceType2Arch(
    {"t1.micro"=>{"Arch"=>"64"},
     "m1.small"=>{"Arch"=>"64"},
     "m1.medium"=>{"Arch"=>"64"},
     "m1.large"=>{"Arch"=>"64"},
     "m1.xlarge"=>{"Arch"=>"64"},
     "m2.xlarge"=>{"Arch"=>"64"},
     "m2.2xlarge"=>{"Arch"=>"64"},
     "m2.4xlarge"=>{"Arch"=>"64"},
     "c1.medium"=>{"Arch"=>"64"},
     "c1.xlarge"=>{"Arch"=>"64"},
     "cc1.4xlarge"=>{"Arch"=>"64Cluster"},
     "cc2.8xlarge"=>{"Arch"=>"64Cluster"},
     "cg1.4xlarge"=>{"Arch"=>"64GPU"}})
  AWSRegionArch2AMI(
    {"us-east-1"=>
      {"32"=>"ami-a0cd60c9",
       "64"=>"ami-aecd60c7",
       "64Cluster"=>"ami-a8cd60c1",
       "64GPU"=>"ami-eccf6285"},
     "us-west-2"=>
      {"32"=>"ami-46da5576",
       "64"=>"ami-48da5578",
       "64Cluster"=>"NOT_YET_SUPPORTED",
       "64GPU"=>"NOT_YET_SUPPORTED"},
     "us-west-1"=>
      {"32"=>"ami-7d4c6938",
       "64"=>"ami-734c6936",
       "64Cluster"=>"NOT_YET_SUPPORTED",
       "64GPU"=>"NOT_YET_SUPPORTED"},
     "eu-west-1"=>
      {"32"=>"ami-61555115",
       "64"=>"ami-6d555119",
       "64Cluster"=>"ami-67555113",
       "64GPU"=>"NOT_YET_SUPPORTED"},
     "ap-southeast-1"=>
      {"32"=>"ami-220b4a70",
       "64"=>"ami-3c0b4a6e",
       "64Cluster"=>"NOT_YET_SUPPORTED",
       "64GPU"=>"NOT_YET_SUPPORTED"},
     "ap-northeast-1"=>
      {"32"=>"ami-2a19aa2b",
       "64"=>"ami-2819aa29",
       "64Cluster"=>"NOT_YET_SUPPORTED",
       "64GPU"=>"NOT_YET_SUPPORTED"},
     "sa-east-1"=>
      {"32"=>"ami-f836e8e5",
       "64"=>"ami-fe36e8e3",
       "64Cluster"=>"NOT_YET_SUPPORTED",
       "64GPU"=>"NOT_YET_SUPPORTED"}})
  SubnetConfig do
    VPC do
      CIDR "10.0.0.0/16"
    end
    Public do
      CIDR "10.0.0.0/24"
    end
  end
end
Resources do
  VPC do
    Type "AWS::EC2::VPC"
    Properties do
      EnableDnsSupport "true"
      EnableDnsHostnames "true"
      CidrBlock do
        Fn__FindInMap "SubnetConfig", "VPC", "CIDR"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackName"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  PublicSubnet do
    Type "AWS::EC2::Subnet"
    Properties do
      VpcId do
        Ref "VPC"
      end
      CidrBlock do
        Fn__FindInMap "SubnetConfig", "Public", "CIDR"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackName"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  InternetGateway do
    Type "AWS::EC2::InternetGateway"
    Properties do
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackName"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  GatewayToInternet do
    Type "AWS::EC2::VPCGatewayAttachment"
    Properties do
      VpcId do
        Ref "VPC"
      end
      InternetGatewayId do
        Ref "InternetGateway"
      end
    end
  end
  PublicRouteTable do
    Type "AWS::EC2::RouteTable"
    Properties do
      VpcId do
        Ref "VPC"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackName"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  PublicRoute do
    Type "AWS::EC2::Route"
    DependsOn "GatewayToInternet"
    Properties do
      RouteTableId do
        Ref "PublicRouteTable"
      end
      DestinationCidrBlock "0.0.0.0/0"
      GatewayId do
        Ref "InternetGateway"
      end
    end
  end
  PublicSubnetRouteTableAssociation do
    Type "AWS::EC2::SubnetRouteTableAssociation"
    Properties do
      SubnetId do
        Ref "PublicSubnet"
      end
      RouteTableId do
        Ref "PublicRouteTable"
      end
    end
  end
  PublicNetworkAcl do
    Type "AWS::EC2::NetworkAcl"
    Properties do
      VpcId do
        Ref "VPC"
      end
      Tags [
        _{
          Key "Application"
          Value do
            Ref "AWS::StackName"
          end
        },
        _{
          Key "Network"
          Value "Public"
        }
      ]
    end
  end
  InboundHTTPPublicNetworkAclEntry do
    Type "AWS::EC2::NetworkAclEntry"
    Properties do
      NetworkAclId do
        Ref "PublicNetworkAcl"
      end
      RuleNumber 100
      Protocol 6
      RuleAction "allow"
      Egress "false"
      CidrBlock "0.0.0.0/0"
      PortRange do
        From 80
        To 80
      end
    end
  end
  InboundHTTPSPublicNetworkAclEntry do
    Type "AWS::EC2::NetworkAclEntry"
    Properties do
      NetworkAclId do
        Ref "PublicNetworkAcl"
      end
      RuleNumber 101
      Protocol 6
      RuleAction "allow"
      Egress "false"
      CidrBlock "0.0.0.0/0"
      PortRange do
        From 443
        To 443
      end
    end
  end
  InboundSSHPublicNetworkAclEntry do
    Type "AWS::EC2::NetworkAclEntry"
    Properties do
      NetworkAclId do
        Ref "PublicNetworkAcl"
      end
      RuleNumber 102
      Protocol 6
      RuleAction "allow"
      Egress "false"
      CidrBlock do
        Ref "SSHFrom"
      end
      PortRange do
        From 22
        To 22
      end
    end
  end
  InboundEmphemeralPublicNetworkAclEntry do
    Type "AWS::EC2::NetworkAclEntry"
    Properties do
      NetworkAclId do
        Ref "PublicNetworkAcl"
      end
      RuleNumber 103
      Protocol 6
      RuleAction "allow"
      Egress "false"
      CidrBlock "0.0.0.0/0"
      PortRange do
        From 1024
        To 65535
      end
    end
  end
  OutboundPublicNetworkAclEntry do
    Type "AWS::EC2::NetworkAclEntry"
    Properties do
      NetworkAclId do
        Ref "PublicNetworkAcl"
      end
      RuleNumber 100
      Protocol 6
      RuleAction "allow"
      Egress "true"
      CidrBlock "0.0.0.0/0"
      PortRange do
        From 0
        To 65535
      end
    end
  end
  PublicSubnetNetworkAclAssociation do
    Type "AWS::EC2::SubnetNetworkAclAssociation"
    Properties do
      SubnetId do
        Ref "PublicSubnet"
      end
      NetworkAclId do
        Ref "PublicNetworkAcl"
      end
    end
  end
  _include 'ec2host2.rb'
  EC2Host do
    Type "AWS::EC2::Instance"
    DependsOn "GatewayToInternet"
    Properties do
      InstanceType do
        Ref "EC2InstanceType"
      end
      KeyName do
        Ref "KeyName"
      end
      ImageId do
        Fn__FindInMap [
          "AWSRegionArch2AMI",
          _{
            Ref "AWS::Region"
          },
          _{
            Fn__FindInMap [
              "AWSInstanceType2Arch",
              _{
                Ref "EC2InstanceType"
              },
              "Arch"
            ]
          }
        ]
      end
      NetworkInterfaces [
        _{
          GroupSet [
            _{
              Ref "EC2SecurityGroup"
            }
          ]
          AssociatePublicIpAddress "true"
          DeviceIndex 0
          DeleteOnTermination "true"
          SubnetId do
            Ref "PublicSubnet"
          end
        }
      ]
    end
  end
  EC2SecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      GroupDescription "Enable access to the EC2 host"
      VpcId do
        Ref "VPC"
      end
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort 22
          ToPort 22
          CidrIp do
            Ref "SSHFrom"
          end
        }
      ]
    end
  end
end
Outputs do
  VPCId do
    Description "VPCId of the newly created VPC"
    Value do
      Ref "VPC"
    end
  end
  PublicSubnet do
    Description "SubnetId of the public subnet"
    Value do
      Ref "PublicSubnet"
    end
  end
  DNSName do
    Description "DNS Name of the EC2 host"
    Value do
      Fn__GetAtt "EC2Host", "PublicDnsName"
    end
  end
  DNSName2 do
    Description "DNS Name of the EC2 host"
    Value do
      Fn__GetAtt "EC2Host2", "PublicDnsName"
    end
  end
end

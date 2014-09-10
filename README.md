# kumogata-practice

## Requirements

- Ruby
- Bundler(Rubygems)
- AWS Security Credentials
- KeyPair for EC2


## Setup

git clone this repo and run tasks.

```
$ gem install bundler
$ bundle
```

## Configure

### ~/.aws/credentials 

```
[default]
aws_access_key_id = AKIXXXXXXXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
region = ap-northeast-1
```

## Create stack from json

```
$ kumogata create cf_templates/VPC_With_PublicIPs_And_DNS.template teststack -p KeyName=YOUR_SSH_PRIVATE_KEYNAME

...

Success

...
Outputs:
{
  "VPCId": "vpc-688f3xxx",
  "PublicSubnet": "subnet-57d90xxx",
  "DNSName": "ec2-xx-xx-xx-x.compute-1.amazonaws.com"
}
```

show-outputs subcommans shows `Outputs` section.

```
$ kumogata show-outputs teststack
{
  "VPCId": "vpc-688f3f0d",
  "PublicSubnet": "subnet-57d90820",
  "DNSName": "ec2-54-86-40-29.compute-1.amazonaws.com"
}
```

### Login via ssh to instance

Refer to Outputs:   "DNSName": "ec2-xx-xx-xx-x.compute-1.amazonaws.com"

```
ssh ec2-user@ec2-xx-xx-xx-x.compute-1.amazonaws.com -i YOUR_PRIVATE_KEY_PATH

...

       __|  __|_  )
       _|  (     /   Amazon Linux AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-ami/2012.03-release-notes/
There are 39 security update(s) out of 243 total update(s) available
Run "sudo yum update" to apply all updates.
Amazon Linux version 2014.03 is available.
[ec2-user@ip-xx-x-x-xxx ~]$ 
```


## Convert json to ruby-script


```
$ kumogata convert cf_templates/VPC_With_PublicIPs_And_DNS.template > converted/VPC_With_PublicIPs_And_DNS.rb
```

### Edit file

copy to new file from `EC2Host` block in`converted/VPC_With_PublicIPs_And_DNS.rb`  (Line:325 to 369)

```
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
```

converted/ec2host2.rb

```
  EC2Host2 do  ## New keyname
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

```

include it from `converted/VPC_With_PublicIPs_And_DNS.rb`.

```
  _include 'ec2host2.rb'
  EC2Host do
    Type "AWS::EC2::Instance"
...
```

Add PublicDnsName of EC2Host2 to Outputs section.

```
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
```

### Update Stack

Validate before update.

```
 $ kumogata validate converted/VPC_With_PublicIPs_And_DNS.rb 
Template validated successfully
````


```
$ kumogata update converted/VPC_With_PublicIPs_And_DNS.rb teststack -p KeyName=YOUR_SSH_PRIVATE_KEYNAME
Updating stack: teststack
2014/09/10 14:27:57 JST: {"LogicalResourceId":"teststack","ResourceStatus":"UPDATE_IN_PROGRESS","ResourceStatusReason":"User Initiated"}
2014/09/10 14:28:02 JST: {"LogicalResourceId":"EC2Host2","ResourceStatus":"CREATE_IN_PROGRESS","ResourceStatusReason":null}
2014/09/10 14:28:04 JST: {"LogicalResourceId":"EC2Host2","ResourceStatus":"CREATE_IN_PROGRESS","ResourceStatusReason":"Resource creation Initiated"}
...

Outputs:
{
  "VPCId": "vpc-688f3f0d",
  "PublicSubnet": "subnet-57d90820",
  "DNSName": "ec2-xx-xx-xx-29.compute-1.amazonaws.com",
  "DNSName2": "ec2-xx-xx-xxx-74.compute-1.amazonaws.com"
}
```


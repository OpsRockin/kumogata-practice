  EC2Host2 do
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


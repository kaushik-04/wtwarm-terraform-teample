Location = "eastus2"
Enumerator = 22
App = "test01"
appid = "12345"
EnvType = "dev"
AppTier = "db"
corpuid = "abc1234"
Workload = "adk34kdn" # This is assigned
SIG_Definition = "Oracle_19.7_202004_RHEL7"
VM_Size = "Standard_D4s_v3"
Data_Disks = {
	dd02 = {
		key = "u02"
		size = 200
		lun = "0"
	},
	dd99 = {
		key = "u99"
		size = 200
		lun = "1"
	},
	dd80 = {
		key = "u80"
		size = 200
		lun = "2"
	}
}
# DB configs
DBsize="s"			
DBport="1522"
AGENTPORT="1832"
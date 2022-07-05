Location = "westus2"
Enumerator = 22
App = "oracle"
appid = "jskora"
EnvType = "test"
AppTier = "db"
corpuid = "ep9123"
Workload = "z1azu1g1"
SIG_Definition = "Oracle_Client_RHEL7"
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
DBport="1521"
AGENTPORT="1831"
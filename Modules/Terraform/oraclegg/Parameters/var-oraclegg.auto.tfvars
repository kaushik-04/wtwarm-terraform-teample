app_resource_group      = "oracle-westus2-test-rg"
app_keyvault_name       = "oracle-westus2-test-kv"
Location = "westus2"
Enumerator = "02"
App = "oracle"
appid = "jskora"
EnvType = "test"
AppTier = "db"
corpuid = "ep9123"
Workload = "z1azu1g1"
SIG_Definition = "Oracle_Client_RHEL7"
VM_Size = "Standard_D4s_v3"
OS_Disk_Size = 128
Zone = 1
Data_Disks = {
	dd02 = {
		key = "u02"
		size = 64
		lun = "0"
	},
	dd99 = {
		key = "u99"
		size = 32
		lun = "1"
	},
	dd80 = {
		key = "u80"
		size = 32
		lun = "2"
	}
}
# DB configs
DBsize="m"			
DBport="1521"
AGENTPORT="1831"

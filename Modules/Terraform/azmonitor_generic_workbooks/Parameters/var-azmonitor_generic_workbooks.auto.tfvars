subscriptionId = "subscription_id"
tenantId = "tenant_id"
resource_group_name = "resource_group"

az_monitoring_generic_workbooks = {
   azgenericworkbook = {
        workbookName                = "VMCPUMETRICWB"
        workbookDisplayName         = "VM  Metric Workbook"
        workbookSourceId            =  "/subscriptions/0ed04194-6098-4e07-af03-c51130e49b37/resourceGroups/monitor-rg"
        workbookSerializedData       =  "{\"version\":\"Notebook/1.0\",\"items\":[{\"type\":1,\"content\":{\"json\":\"# Workbook Parameters\"},\"name\":\"text - 5\"},{\"type\":9,\"content\":{\"version\":\"KqlParameterItem/1.0\",\"crossComponentResources\":[\"{Subscriptions}\"],\"parameters\":[{\"id\":\"1db5ee15-fe52-458b-91d1-7ee39d8c2cd3\",\"version\":\"KqlParameterItem/1.0\",\"name\":\"Subscriptions\",\"type\":6,\"isRequired\":true,\"value\":\"value::1\",\"typeSettings\":{\"additionalResourceOptions\":[\"value::1\"],\"includeAll\":false}},{\"id\":\"9732eff8-fb57-4cbd-8ade-5ae746f33760\",\"version\":\"KqlParameterItem/1.0\",\"name\":\"Workspaces\",\"type\":5,\"isRequired\":true,\"query\":\"where type =~ 'microsoft.operationalinsights/workspaces'\\r\\n| summarize by id\",\"crossComponentResources\":[\"{Subscriptions}\"],\"value\":\"value::1\",\"typeSettings\":{\"resourceTypeFilter\":{\"microsoft.operationalinsights/workspaces\":true},\"additionalResourceOptions\":[\"value::1\"],\"showDefault\":false},\"queryType\":1,\"resourceType\":\"microsoft.resourcegraph/resources\"},{\"id\":\"5f8cce4b-9c4c-47da-8683-7e5ccc9faed3\",\"version\":\"KqlParameterItem/1.0\",\"name\":\"TimeRange\",\"type\":4,\"value\":{\"durationMs\":3600000},\"typeSettings\":{\"selectableValues\":[{\"durationMs\":300000,\"createdTime\":\"2018-10-04T22:01:18.372Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":900000,\"createdTime\":\"2018-10-04T22:01:18.372Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":1800000,\"createdTime\":\"2018-10-04T22:01:18.372Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":3600000,\"createdTime\":\"2018-10-04T22:01:18.372Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":14400000,\"createdTime\":\"2018-10-04T22:01:18.374Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":43200000,\"createdTime\":\"2018-10-04T22:01:18.374Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":86400000,\"createdTime\":\"2018-10-04T22:01:18.374Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":172800000,\"createdTime\":\"2018-10-04T22:01:18.374Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":259200000,\"createdTime\":\"2018-10-04T22:01:18.375Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":604800000,\"createdTime\":\"2018-10-04T22:01:18.375Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":1209600000,\"createdTime\":\"2018-10-04T22:01:18.375Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":2592000000,\"createdTime\":\"2018-10-04T22:01:18.375Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":5184000000,\"createdTime\":\"2018-10-04T22:01:18.375Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false},{\"durationMs\":7776000000,\"createdTime\":\"2018-10-04T22:01:18.375Z\",\"isInitialTime\":false,\"grain\":1,\"useDashboardTimeRange\":false}],\"allowCustom\":true}}],\"style\":\"pills\",\"queryType\":1,\"resourceType\":\"microsoft.resourcegraph/resources\"},\"name\":\"parameters - 2\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Processor' and CounterName == '% Processor Time' and InstanceName == '_Total'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Processor' and CounterName == '% Processor Time' and InstanceName == '_Total' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"aggregation\":3,\"title\":\"% Processor Time\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\",\"tileSettings\":{\"showBorder\":false,\"titleContent\":{\"columnMatch\":\"Computer\",\"formatter\":1},\"leftContent\":{\"columnMatch\":\"AggregatedValue\",\"formatter\":12,\"formatOptions\":{\"palette\":\"auto\"},\"numberFormat\":{\"unit\":17,\"options\":{\"maximumSignificantDigits\":3,\"maximumFractionDigits\":2}}}},\"graphSettings\":{\"type\":0,\"topContent\":{\"columnMatch\":\"Computer\",\"formatter\":1},\"centerContent\":{\"columnMatch\":\"AggregatedValue\",\"formatter\":1,\"numberFormat\":{\"unit\":17,\"options\":{\"maximumSignificantDigits\":3,\"maximumFractionDigits\":2}}}},\"chartSettings\":{\"group\":\"Computer\",\"createOtherGroup\":null},\"mapSettings\":{\"locInfo\":\"LatLong\",\"sizeSettings\":\"AggregatedValue\",\"sizeAggregation\":\"Sum\",\"legendMetric\":\"AggregatedValue\",\"legendAggregation\":\"Sum\",\"itemColorSettings\":{\"type\":\"heatmap\",\"colorAggregation\":\"Sum\",\"nodeColorField\":\"AggregatedValue\",\"heatmapPalette\":\"greenRed\"}}},\"name\":\"query - 0\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Processor' and CounterName == '% Privileged Time' and InstanceName == '_Total'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Processor' and CounterName == '% Privileged Time' and InstanceName == '_Total' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"% Privledged Time\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\",\"chartSettings\":{\"group\":\"Computer\",\"createOtherGroup\":null}},\"name\":\"query - 1\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == '% Used Inodes' \\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == '% Used Inodes' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"% Used Inodes\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 2\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Free Megabytes'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Free Megabytes' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Logical Disk - Free Megabytes\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 3\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == '% Used Space'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == '% Used Space' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Logical Disk - % Used Space\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 4\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Disk Transfers/sec'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Disk Transfers/sec' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Disk Transfers/Sec\",\"timeContext\":{\"durationMs\":86400000},\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"/subscriptions/4abf9863-c25e-4e4e-ace9-55330c103864/resourceGroups/poc-att/providers/microsoft.operationalinsights/workspaces/poc-att\"],\"visualization\":\"areachart\"},\"name\":\"query - 5\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Disk Reads/sec'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Disk Reads/sec' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Logical Disk - Disk Reads/Sec\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"Logical Disk - Disk Reads/sec\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Disk Writes/sec'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Logical Disk' and CounterName == 'Disk Writes/sec' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Logical Disk - Disk Writes/sec\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 7\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Memory' and CounterName == 'Available MBytes Memory'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Memory' and CounterName == 'Available MBytes Memory' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Memory - Available MBytes\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 8\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Memory' and CounterName == '% Used Memory'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Memory' and CounterName == '% Used Memory' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Memory - % Used Memory\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 9\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Memory' and CounterName == '% Used Swap Space'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Memory' and CounterName == '% Used Swap Space' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Memory - % Used Swap Space\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 10\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = InsightsMetrics\\r\\n| where Namespace == 'Network' and Name == 'ReadBytesPerSecond' \\r\\n| summarize AggregatedValue = avg(Val) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| project Computer;\\r\\nInsightsMetrics\\r\\n| where Namespace == 'Network' and Name == 'ReadBytesPerSecond'and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(Val) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Network - Read Bytes/Sec\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 11\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"let TopComputers = Perf\\r\\n| where ObjectName == 'Network' and CounterName == 'Total Bytes Received'\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer\\r\\n| sort by AggregatedValue desc\\r\\n| limit 5\\r\\n| project Computer;\\r\\nPerf\\r\\n| where ObjectName == 'Network' and CounterName == 'Total Bytes Received' and Computer in (TopComputers)\\r\\n| summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 1h) | render timechart\",\"size\":0,\"title\":\"Networking - Write Bytes/Sec\",\"timeContext\":{\"durationMs\":3600000},\"timeContextFromParameter\":\"TimeRange\",\"queryType\":0,\"resourceType\":\"microsoft.operationalinsights/workspaces\",\"crossComponentResources\":[\"{Workspaces}\"],\"visualization\":\"areachart\"},\"name\":\"query - 12\"}],\"isLocked\":false,\"fallbackResourceIds\":[]}",
     }
}

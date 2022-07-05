package com.microsoft.att;

public class Constants {
    public static final String FAKE_SUBSCRIPTION_URL = "/subscriptions/0fb21625-3946-4f04-8934-f62e93621e1a/resourcegroups/pipelinealertrg/providers/microsoft.compute/virtualmachines/wcus-r2-gen2";

    public static final String FAKE_SUBSCRIPTION = "{  'id': '/subscriptions/291bba3f-e0a5-47bc-a099-3bdcb2a50a05',  'subscriptionId': '291bba3f-e0a5-47bc-a099-3bdcb2a50a05',  'tenantId': '31c75423-32d6-4322-88b7-c478bdde4858',  'displayName': 'Example Subscription',  'state': 'Enabled',  'subscriptionPolicies': {    'locationPlacementId': 'Internal_2014-09-01',    'quotaId': 'Internal_2014-09-01',    'spendingLimit': 'Off'  },  'authorizationSource': 'Bypassed',  'managedByTenants': [    {      'tenantId': '8f70baf1-1f6e-46a2-a1ff-238dac1ebfb7'    }  ],  'tags': {    'appid': '12345'  }}";

    public static final String FAKE_ALERT =  "{" +
            "'schemaId':'azureMonitorCommonAlertSchema'," +
            "'data':{" +
            "'essentials': {" +
            "'alertId':'/subscriptions/<subscription ID>/providers/Microsoft.AlertsManagement/alerts/b9569717-bc32-442f-add5-83a997729330'," +
            "'alertRule':'WCUS-R2-Gen2'," +
            "'severity': 'Sev3'," +
            "'signalType': 'Metric'," +
            "'monitorCondition': 'Resolved'," +
            "'monitoringService':'Platform'," +
            "'alertTargetIDs': ['/subscriptions/0fb21625-3946-4f04-8934-f62e93621e1a/resourcegroups/pipelinealertrg/providers/microsoft.compute/virtualmachines/wcus-r2-gen2']," +
            "'originAlertId':'3f2d4487-b0fc-4125-8bd5-7ad17384221e_PipeLineAlertRG_microsoft.insights_metricAlerts_WCUS-R2-Gen2_-117781227'," +
            "'firedDateTime':'2019-03-22T13:58:24.3713213Z'," +
            "'resolvedDateTime': '2019-03-22T14:03:16.2246313Z'," +
            "'description': ''," +
            "'essentialsVersion': '1.0','alertContextVersion': '1.0'" +
            "}," +
            "'alertContext':{" +
            "'properties': null," +
            "'conditionType':'SingleResourceMultipleMetricCriteria'," +
            "'condition': {" +
            "'windowSize': 'PT5M'," +
            "'allOf': [{" +
            "'metricName': 'Percentage CPU'," +
            "'metricNamespace':'Microsoft.Compute/virtualMachines'," +
            "'operator':'GreaterThan'," +
            "'threshold':'25'," +
            "'timeAggregation': 'Average'," +
            "'dimensions':[{" +
            "'name': 'ResourceId'," +
            "'value': '3efad9dc-3d50-4eac-9c87-8b3fd6f97e4e'}]," +
            "'metricValue': 7.727}]} }  }}";
}

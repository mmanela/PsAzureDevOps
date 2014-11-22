$here = Split-Path -Parent $MyInvocation.MyCommand.Path

"$here\..\functions\*.ps1", "$here\..\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }


Describe "Get-MyWorkItems" {


    $getQueryData = '{
  "workItems":[
    {"id":2,"url":"http://someUrl/DefaultCollection/_apis/wit/workItems/2"},
    {"id":3,"url":"http://someUrl/DefaultCollection/_apis/wit/workItems/3"},
    {"id":1,"url":"http://someUrl/DefaultCollection/_apis/wit/workItems/1"}
  ]
 }'

    $getWorkItemData = '{ "value": [
    {
        "id":  1,
        "rev":  2,
        "fields":  {
                       "System.Id":  1,
                       "System.WorkItemType":  "Feature",
                       "System.State":  "In Progress",
                       "System.AssignedTo":  "John Smith",
                       "System.CreatedDate":  "2014-11-19",
                       "System.CreatedBy":  "John Smith",
                       "System.ChangedDate":  "2014-11-19",
                       "System.ChangedBy":  "John Smith",
                       "System.Title":  "Fix the drop down"
                   },
        "url":  "http://someUrl/DefaultCollection/_apis/wit/workItems/1"
    },
    {
        "id":  2,
        "rev":  1,
        "fields":  {
                       "System.Id":  2,
                       "System.WorkItemType":  "Bug",
                       "System.State":  "New",
                       "System.CreatedDate":  "2014-11-11",
                       "System.AssignedTo":  "Henry Hank",
                       "System.CreatedBy":  "Heather Harmon",
                       "System.ChangedDate":  "2014-11-15",
                       "System.ChangedBy":  "Peter Piper",
                       "System.Title":  "Resize the text box"
                   },
        "url":  "http://someUrl/DefaultCollection/_apis/wit/workItems/2"
    },
    {
        "id":  3,
        "rev":  1,
        "fields":  {
                       "System.Id":  3,
                       "System.WorkItemType":  "Bug",
                       "System.State":  "In Progress",
                       "System.CreatedDate":  "2014-11-10",
                       "System.AssignedTo":  "Boris Barry",
                       "System.CreatedBy":  "Matt Mayor",
                       "System.ChangedDate":  "2014-11-16",
                       "System.ChangedBy":  "Peter Piper",
                       "System.Title":  "Improve the performance"
                   },
        "url":  "http://someUrl/DefaultCollection/_apis/wit/workItems/3"
    }
]}'


    Mock getUrl { return (ConvertFrom-Json $getWorkItemData )} -ParameterFilter { $urlStr -like "*_apis/wit/workitems*" }

    Mock postUrl { return (ConvertFrom-Json $getQueryData )} -ParameterFilter { $urlStr -like "*_apis/wit/wiql*" }

    Context "When querying with default arguments" {
        $result = Get-MyWorkItems -Project p1 -Account a1
        

        It "returns all work items"{
            $result.count | Should be 3
        }


        It "returns certain properties on top level object"{
            $result[0].Title        | Should be "Resize the text box"
            $result[0].WorkItemType | Should be "Bug"
            $result[0].State        | Should be "New"
            $result[0].AssignedTo   | Should be "Henry Hank"
            $result[0].CreatedBy    | Should be "Heather Harmon"
        }

        It "will return in sort order"{
            $result[0].Id | Should be 2
            $result[1].Id | Should be 3
            $result[2].Id | Should be 1
        }
    }


    Context "When querying with top 2" {
        $result = Get-MyWorkItems -Project p1 -Account a1 -Take 2

        It "returns just 2 work items"{
            $result.count | Should be 2
        }

        It "will return the first 2 in sort order"{
            $result[0].Id | Should be 2
            $result[1].Id | Should be 3
        }
    }

}

# Format work items to make them easily display
# But we still persist the raw field data in the Fields property
function formatWorkItems($workItems) {
	$workItems = $workItems.fields | 
	    ForEach-Object { 
	            [PSCustomObject]@{
	                Id=$_.'System.Id'
	                Title=$_.'System.Title'
	                WorkItemType=$_.'System.WorkItemType'
	                AssignedTo=$_.'System.AssignedTo'
	                CreatedBy=$_.'System.CreatedBy'
	                CreatedDate=$_.'System.CreatedDate'
	                ChangedDate=$_.'System.ChangedDate'
	                State=$_.'System.State'
	                Fields=$_
	            } 
	        }


    # Add type name
    $workItems | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'WorkItem') }
	
	return $workItems
}
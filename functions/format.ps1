
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

function formatBuilds($builds) {
    
    # Add type name
    $builds | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'Build') }
	
	return $builds
}

function formatCoverage($coverage) {

 	$coverage = $coverage | 
	    ForEach-Object { 
	            [PSCustomObject]@{
	                Label=$_.'label'
	                Build=$_.'build'
	                Coverage="$($_.'coverage') %"
	            } 
	        }

    # Add type name
    $coverage | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'Coverage') }
	
	return $coverage
}

function formatArtifact($artifactData, $artifactName) {

 	$artifact = $artifactData | 
	    ForEach-Object { 
	            [PSCustomObject]@{
					Artifact=$artifactName
	                Type=$_.'type'
	                Data=$_.'data'
	                DownloadURL="$($_.'downloadurl') %"
	            } 
	        }

    # Add type name
    $artifact | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'Artifact') }
	
	return $artifact
}
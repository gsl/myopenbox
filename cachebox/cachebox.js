
function popup(lnk) { 
	window.cbx_detail = window.open(lnk.href + "&layout=0","cbx_detail","height=400,width=600,status=0,toolbar=0,location=0,menubar=0,directories=0,scrollbars=1,resizable=1"); 
	// this is a workaround for a bug in FireFox that prevents a popup window from displaying above the opening window if it's already open 
	setTimeout("window.cbx_detail.focus();",100); 
	return false; 
} 

function setEvictPolicy(policy) { 
	var frm = document.frmAgentConfig; 
	var pol = policy.replace(/:\s*$/,'').split(":"); 
	frm.evictpolicy.value = pol[0]; 
	frm.evictpolicy.onchange(); 
	if (pol.length > 1 && (typeof frm.evictafter != "undefined")) { frm.evictafter.value = pol[1]; } 
} 

function selectRecommendation(input) { 
	if (input.checked == true) { 
		var td = input.parentNode.parentNode; 
		var opt = td.getElementsByTagName("INPUT"); 
		for (var x = 0; x < opt.length; x++) { 
			if (opt[x] != input) { opt[x].checked = false; } 
		} 
	} 
} 

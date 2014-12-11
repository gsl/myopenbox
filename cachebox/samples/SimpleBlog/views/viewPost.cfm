<cfoutput>
	<div class="blogPost">
		<div class="title">#rc.qPost.Title#</div>
	
		<div class="postBody">#rc.qPost.EntryBody#</div>
		<div class="author">Posted By: #rc.qPost.author#</div>
		<div class="date">#dateFormat(rc.qPost.time,"medium")# #timeFormat(rc.qPost.time,"short")#</div>
		
		<div class="postComments">
			<h3>Comments:</h3>
			
			<cfloop query="rc.qComments">
				<div class="comment">
					<div class="commentBody">#rc.qComments.comment#</div>
					<div class="commentTime">#dateFormat(rc.qComments.time,"medium")# #timeFormat(rc.qComments.time,"short")#</div>
				</div>
			</cfloop>
			<div><h3>Enter your comment:</h3></div>
			<cfform action="#Event.buildLink('general.doAddComment')#" method="POST">
				<cftextarea name="commentField" cols="40" rows="8"></cftextarea>
				<p><cfinput name="submit" type="submit" value="Submit Comment">
				<p><input type="hidden" name="ID" value="#rc.ID#">
			</cfform>
		</div>
	</div>
</cfoutput>


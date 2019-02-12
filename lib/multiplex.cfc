component {
	this.ongoing=StructNew();
	this.returned=StructNew();
	this.Logs=ArrayNew(1);

	any function start(name, num, f, timeout=10000) {
		local.Depth=arguments.num;
		local.IsOriginal=false;

		this.log("[#local.Depth#] Lock Check Original");
		lock name=arguments.name type="exclusive" timeout="10" {
			if(NOT StructKeyExists(this.ongoing, arguments.name)) {
				local.IsOriginal=true;
				this.ongoing[arguments.name]=1;
			} else {
				this.ongoing[arguments.name]=this.ongoing[arguments.name]+1;
			}
		}
		this.log("[#local.Depth#] Exit Lock Check Original");

		if(local.IsOriginal) {
			this.log("[#local.Depth#] Call function");
			local.toReturn = f();
			this.log("[#local.Depth#] Lock Set Returned for Original");
			lock name=arguments.name type="exclusive" timeout="10" {
				this.returned[arguments.name]=local.toReturn;
				this.log("[#local.Depth#] Set Returned");
			}
			this.log("[#local.Depth#] Exit Lock Set Returned for Original");
		}
		local.loopCount=0;
		try {
			if(NOT local.IsOriginal) {
				local.waitStart=GetTickCount();
				this.log("[#local.Depth#] Start Wait Loop");
				while(NOT StructKeyExists(this.returned, arguments.name)) {
					local.loopCount++;
					sleep(500);
					if(GetTickCount()-local.waitStart GT arguments.timeout) {
						throw("[#local.Depth#] wait timeout exceeded");
					}
				}
				this.log("[#local.Depth#] End Wait Loop");
			}
			this.log("[#local.Depth#] Lock Set Return from Orignal");
			lock name=arguments.name type="readonly" timeout="10" {
				local.toReturn = this.returned[arguments.name];
			}
			this.log("[#local.Depth#] Exit Lock Set Return from Orignal");
		} catch (Any e) {
			this.log(e.message);
			rethrow;
		} finally {
			this.log("[#local.Depth#] Loops: #LoopCount#");
			this.log("[#local.Depth#] Lock Decrement and Destroy");
			lock name=arguments.name type="exclusive" timeout="10" {
				this.log("[#local.Depth#] Reduce from #this.ongoing[arguments.name]# to #this.ongoing[arguments.name]-1#");
				this.ongoing[arguments.name]=this.ongoing[arguments.name]-1;
				if(this.ongoing[arguments.name] EQ 0) {
					this.log("[#local.Depth#] Deleting");
					StructDelete(this.ongoing, arguments.name);
					StructDelete(this.returned, arguments.name);
				}
			}
			this.log("[#local.Depth#] Exit Lock Decrement and Destroy");
		}
		return local.toReturn;
	}

	public any function log(t) {
		ArrayAppend(this.Logs, Now() & " :: " & t);
	}
}
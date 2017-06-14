/*
* Copyright (c) 2010 AtTask, Inc.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
* documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
* rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
* Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
* WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
* OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package com.attask.api
{
	import flash.net.*;
	import flash.utils.Dictionary;

	public class StreamClient
	{
		// Supported object codes
		public static const OBJCODE_PROJECT:String = "proj";
		public static const OBJCODE_TASK:String = "task";
		public static const OBJCODE_ISSUE:String = "optask";
		public static const OBJCODE_TEAM:String = "team";
		public static const OBJCODE_HOUR:String = "hour";
		public static const OBJCODE_TIMESHEET:String = "tshet";
		public static const OBJCODE_USER:String = "user";
		public static const OBJCODE_ASSIGNMENT:String = "assgn";
		public static const OBJCODE_USER_PREF:String = "userpf";
		public static const OBJCODE_CATEGORY:String = "ctgy";
		public static const OBJCODE_CATEGORY_PARAMETER:String = "ctgypa";
		public static const OBJCODE_PARAMETER:String = "param";
		public static const OBJCODE_PARAMETER_GROUP:String = "pgrp";
		public static const OBJCODE_PARAMETER_OPTION:String = "popt";
		public static const OBJCODE_PARAMETER_VALUE:String = "pval";
		public static const OBJCODE_ROLE:String = "role";
		public static const OBJCODE_GROUP:String = "group";
		public static const OBJCODE_NOTE:String = "note";
		public static const OBJCODE_DOCUMENT:String = "docu";
		public static const OBJCODE_DOCUMENT_VERSION:String = "docv";
		public static const OBJCODE_EXPENSE:String = "expns";
		public static const OBJCODE_CUSTOM_ENUM:String = "custem";
		
		public static const METH_DELETE:AtTaskRequestMethod = new AtTaskRequestMethod(URLRequestMethod.POST, "DELETE");
		public static const METH_GET:AtTaskRequestMethod    = new AtTaskRequestMethod(URLRequestMethod.GET);
		public static const METH_POST:AtTaskRequestMethod   = new AtTaskRequestMethod(URLRequestMethod.POST);
		public static const METH_PUT:AtTaskRequestMethod    = new AtTaskRequestMethod(URLRequestMethod.POST, "PUT");
		
		private static const PATH_LOGIN:String  = "/login";
		private static const PATH_LOGOUT:String = "/logout";
		private static const PATH_SEARCH:String = "/search";		
		
		protected var openRequests:Dictionary;
		
		protected var hostname:String;
		
		protected var sessionID:String;
		
		public function StreamClient(hostname:String)
		{
			openRequests = new Dictionary();
			this.hostname = hostname;
		}
		
		public function login(username:String, password:String, callback:Function = null):void {
			var params:Object = {"username": username, "password": password};
			
			request(PATH_LOGIN, params, null, METH_GET, function(response:Object, fail:Object):void {
				if(response != null)
					sessionID = response['sessionID'];
					
				//pass the response along
				callback(response, fail);				
			});
		}
		
		public function logout(callback:Function=null):void {
			if(sessionID) {
				var params:Object = {"sessionID": sessionID};
				request(PATH_LOGOUT, params, null, METH_GET, callback);
			}else {
				if(callback !== null)
					callback(null,{"success": false}); //indicate failure
			}
		}
		
		public function get(objCode:String, objID:String, query:Object, fields:Vector.<String>, callback:Function=null):void {
			request("/"+objCode+"/"+objID, query,fields,METH_GET,callback);
		}
		
		public function remove(objCode:String, objID:String, force:Boolean=false, callback:Function=null):void {
			var params:Object = {"force": force};
			
			request("/"+objCode+"/"+objID, params,null,METH_DELETE,callback);
		}
		
		public function search(objCode:String, query:Object, fields:Vector.<String>, callback:Function=null):void {
			request("/"+objCode+PATH_SEARCH, query,fields,METH_GET,callback);
		}
		
		public function post(objCode:String, params:Object, fields:Vector.<String>, callback:Function=null):void {
			request("/"+objCode, params,fields,METH_POST,callback);
		}
		
		public function put(objCode:String, objID:String, params:Object, fields:Vector.<String>, callback:Function=null):void {
			request("/"+objCode+"/"+objID, params,fields,METH_PUT,callback);
		}
		
		private function request(path:String, params:Object, fields:Vector.<String>, method:AtTaskRequestMethod, callback:Function=null):void {
			var req:AtTaskRequest = new AtTaskRequest(hostname, method);
			
			//We need to hold on to a reference or the GC might clear this during the load.
			openRequests[req] = callback;
			
			if(sessionID != null) {
				if(params == null) params = new Object();
				params['sessionID'] = sessionID;
			}
			
			req.call(path, params, fields, handleRequestLoad);
		}
		
		private function handleRequestLoad(target:AtTaskRequest):void {
			var resultCallback:Function = openRequests[target];
			if (resultCallback === null) {
				delete openRequests[target];
				return;
			}
			
			if (target.success) {
				var data:Object = ('data' in target.data) ? target.data.data : target.data;
				resultCallback(data, null);
			} else {
				resultCallback(null, target.data);
			}
			
			delete openRequests[target];
		}
	}
}
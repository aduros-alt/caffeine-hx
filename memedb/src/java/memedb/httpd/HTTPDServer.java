/*
* Copyright 2008 The MemeDB Contributors (see CONTRIBUTORS)
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy of
* the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
*/

package memedb.httpd;

import org.mortbay.jetty.Connector;
import org.mortbay.jetty.Handler;
import org.mortbay.jetty.Server;
import org.mortbay.jetty.handler.ContextHandler;
import org.mortbay.jetty.handler.DefaultHandler;
import org.mortbay.jetty.handler.HandlerCollection;
import org.mortbay.jetty.handler.ResourceHandler;
import org.mortbay.jetty.nio.SelectChannelConnector;

import memedb.MemeDB;
import memedb.utils.Logger;

public class HTTPDServer extends Server {

	protected Server server = null;

	final protected MemeDB memeDB;

	public HTTPDServer(MemeDB memeDB) {
		this.memeDB=memeDB;
	}

	public void init() throws Exception {
		int port = Integer.parseInt(memeDB.getProperty("server.port"));
		server = new Server();
		server.setSendServerVersion(false);
// 		server.setGracefulShutdown(5000);

		Connector connector=new SelectChannelConnector();
		connector.setPort(port);
		server.setConnectors(new Connector[]{connector});

		ContextHandler context = new ContextHandler();
		context.setContextPath("/");
		server.setHandler(context);

		HandlerCollection handlers=new HandlerCollection();
		ResourceHandler resourceHandler=new ResourceHandler();
		resourceHandler.setResourceBase(memeDB.getProperty("server.www.path"));
		handlers.setHandlers(new Handler[] {
			new MemeDBHandler(memeDB),
			resourceHandler,
			new DefaultHandler()
		});
		context.setHandler(handlers);

		try {
			server.start();
		} catch (Exception e) {
			Logger.get(getClass()).error(e,"Error starting Jetty");
			throw e;
		}
	}

	public void shutdown() {
		try {
			Logger.get(getClass()).debug("Stopping Jetty");
			server.stop();
		} catch (Exception e) {
			Logger.get(getClass()).error(e,"Error shutting down Jetty");
		}
	}
}

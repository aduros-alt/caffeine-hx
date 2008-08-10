package test;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Test;

import memedb.backend.BackendException;
import memedb.document.Document;
import memedb.document.DocumentCreationException;
import memedb.document.JSONDocument;
import memedb.views.ViewException;
import memedb.views.ViewManager;

public class AllDocsViewTest extends BaseTest{
	@Test
	public void testAllDocs() {
		java.util.Map<String,String> options = new java.util.HashMap<String,String>();
		JSONArray ar = null;
		try {
			JSONObject json = db.getViewManager().getViewResults("foodb", "_all_docs", 
ViewManager.DEFAULT_FUNCTION_NAME,options);
			System.out.println(json.toString(2));
			ar = json.getJSONArray("rows");

			for (int i=0; i< ar.length();i++) {
				JSONObject obj = ar.getJSONObject(i);
				String id = obj.getString("id");
				assertTrue(backend.doesDocumentExist("foodb", id));
			}
		} catch (ViewException e) {}
		JSONDocument newdoc = null ;
		try {
			newdoc = (JSONDocument) Document.newDocument(backend, "foodb", null,"unittest");
			newdoc.put("foo", "bar");
			newdoc=(JSONDocument) backend.saveDocument(newdoc);
		} catch (DocumentCreationException e) {
			e.printStackTrace();
		} catch (BackendException e) {
			e.printStackTrace();
		}
		assertNotNull(newdoc);

		try {
			JSONObject json2 = db.getViewManager().getViewResults("foodb", "_all_docs", 
ViewManager.DEFAULT_FUNCTION_NAME,options);
			boolean found=false;
			ar = json2.getJSONArray("rows");
			for (int i=0; i< ar.length();i++) {
				JSONObject obj = ar.getJSONObject(i);
				String id = obj.getString("id");
				if (id.equals(newdoc.getId())) {
					found=true;
				}
			}
			assertTrue(found);
			System.out.println(json2.toString(2));
		} catch (ViewException e) {}
		try {
			backend.deleteDocument("foodb", newdoc.getId());
		} catch (BackendException e) {
			e.printStackTrace();
		}
	}
}

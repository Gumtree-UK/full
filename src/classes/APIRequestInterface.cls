public interface APIRequestInterface {
	String signUrl(String url);
	HttpResponse sendRequest(String method, String path, String body);
}
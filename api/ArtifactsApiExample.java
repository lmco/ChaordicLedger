import io.swagger.client.*;
//import io.swagger.client.auth.*;
//import io.swagger.client.model.*;
import io.swagger.client.api.ArtifactsApi;

import java.io.File;
import java.util.*;

public class ArtifactsApiExample {

    public static void main(String[] args) {

        ArtifactsApi apiInstance = new ArtifactsApi();
        try {
            apiInstance.getAllArtifactMetadata();
        } catch (ApiException e) {
            System.err.println("Exception when calling ArtifactsApi#getAllArtifactMetadata");
            e.printStackTrace();
        }
    }
}

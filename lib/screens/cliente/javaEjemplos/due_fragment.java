package com.example.foofmaps.dueño.fragments;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.example.foofmaps.Config;
import com.example.foofmaps.R;
import com.example.foofmaps.dueño.vista_dueno2;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.MapStyleOptions;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class MapsDueFragment extends Fragment implements OnMapReadyCallback, vista_dueno2.OnRestaurantStatusChangeListener {

    private GoogleMap mMap;
    private Marker restauranteMarker;
    private int restauranteId = -1; // Inicializa con un valor por defecto

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_maps_due, container, false);
        // Obtener los argumentos del Bundle
        Bundle bundle = getArguments();
        if (bundle != null) {
            restauranteId = bundle.getInt("restaurante_id", -1);
            Log.d("id_rest_enmap", String.valueOf(restauranteId));

            // Aquí construimos la URL para obtener los datos del restaurante
            String controladorURL1 = Config.CONTROLADOR_URL + "cont_rest.php?restaurante_id=" + restauranteId;
            Log.d("BeforeURL", "Before defining controladorURL1");
            Log.d("controladorURL1", controladorURL1);

            // Hacemos la solicitud para obtener los datos del restaurante
            RequestQueue requestQueue = Volley.newRequestQueue(requireContext());
            StringRequest stringRequest = new StringRequest(Request.Method.GET, controladorURL1,
                    response -> {
                        try {
                            // Parsear la respuesta JSON
                            JSONArray jsonArray = new JSONArray(response);
                            if (jsonArray.length() > 0) {
                                JSONObject jsonObject = jsonArray.getJSONObject(0); // Tomar el primer objeto
                                String nomRest = jsonObject.getString("nom_rest");
                                JSONObject ubicacion = jsonObject.getJSONObject("ubicacion");
                                double latitud = Double.parseDouble(ubicacion.getString("latitud"));
                                double longitud = Double.parseDouble(ubicacion.getString("longitud"));
                                int estadoRestaurante = jsonObject.getInt("estado");
                                Log.d("Restaurante___datos ", nomRest + " - " + latitud + " - " + longitud);

                                LatLng restauranteLatLng = new LatLng(latitud, longitud);

                                // Inicializar el mapa
                                SupportMapFragment mapFragment = (SupportMapFragment) getChildFragmentManager().findFragmentById(R.id.map_dueno);
                                if (mapFragment != null) {
                                    mapFragment.getMapAsync(googleMap -> {
                                        mMap = googleMap;
                                        // Aplicar estilo personalizado
                                        boolean success = mMap.setMapStyle(MapStyleOptions.loadRawResourceStyle(requireContext(), R.raw.map_style_no_labels));

                                        // Agregar marcador
                                        if (restauranteMarker != null) {
                                            restauranteMarker.remove(); // Eliminar el marcador anterior
                                        }
                                        restauranteMarker = mMap.addMarker(new MarkerOptions().position(restauranteLatLng).title(nomRest));
                                        // Mover cámara
                                        mMap.moveCamera(CameraUpdateFactory.newLatLngZoom(restauranteLatLng, 16));
                                        // Dentro de tu método donde creas los marcadores, puedes tener algo como esto:
                                        updateMarkerColor(estadoRestaurante, latitud, longitud);
                                    });
                                } else {
                                    Log.e("MapFragment", "Map fragment is null");
                                }
                            }
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }, error -> Log.e("FetchDataError", "Error fetching data: " + error.toString()));

            requestQueue.add(stringRequest);
        } else {
            Log.d("BundleCheck", "Bundle is null");
        }

        if (getActivity() instanceof vista_dueno2) {
            ((vista_dueno2) getActivity()).setOnRestaurantStatusChangeListener(this);
            int initialStatus = ((vista_dueno2) getActivity()).getInitialRestaurantStatus();
            onStatusChange(initialStatus); // Establece el color del marcador según el estado inicial
            ((vista_dueno2) getActivity()).updateSwitchState(initialStatus); // Actualiza el estado del switch
        }

        return view;
    }

    @Override
    public void onMapReady(GoogleMap googleMap) {
        mMap = googleMap;
    }

    @Override
    public void onStatusChange(int status) {
        if (mMap != null && restauranteMarker != null) {
            updateMarkerColor(status, restauranteMarker.getPosition().latitude, restauranteMarker.getPosition().longitude);
        }
    }

    private Marker currentMarker; // Guarda una referencia al marcador actual

    private void updateMarkerColor(int status, double latitud, double longitud) {
        if (currentMarker != null) {
            currentMarker.remove(); // Elimina el marcador anterior
        }
        if (status == 1) {
            // El restaurante está abierto, así que el marcador es verde
            MarkerOptions markerOptions = new MarkerOptions()
                    .position(new LatLng(latitud, longitud))
                    .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_GREEN));
            currentMarker = mMap.addMarker(markerOptions);
        } else {
            // El restaurante está cerrado, así que el marcador es rojo
            MarkerOptions markerOptions = new MarkerOptions()
                    .position(new LatLng(latitud, longitud))
                    .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED));
            currentMarker = mMap.addMarker(markerOptions);
        }
    }

}

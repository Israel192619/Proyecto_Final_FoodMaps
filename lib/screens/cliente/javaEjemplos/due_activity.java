package com.example.foofmaps.dueño;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.MenuItem;
import android.widget.ImageView;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.bumptech.glide.Glide;
import com.example.foofmaps.Config;
import com.example.foofmaps.R;
import com.example.foofmaps.dueño.fragments.MapsDueFragment;
import com.example.foofmaps.dueño.fragments.SettingsDuenoFragment;
import com.example.foofmaps.dueño.fragments.dueno_bebidas;
import com.example.foofmaps.dueño.fragments.dueno_platos;
import com.google.android.material.bottomnavigation.BottomNavigationView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class vista_dueno2 extends AppCompatActivity {

    public interface OnRestaurantStatusChangeListener {
        void onStatusChange(int status);
    }

    private OnRestaurantStatusChangeListener onRestaurantStatusChangeListener;

    private MapsDueFragment mapsDueFragment;
    private SettingsDuenoFragment settingsDuenoFragment;
    private dueno_platos platos_Fragment;
    private dueno_bebidas bebidas_Fragment;
    private String nombreRestaurante;
    private int initialRestaurantStatus = -1;
    private boolean doubleBackToExitPressedOnce = false;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_maps2);
        SharedPreferences sharedPreferences = getSharedPreferences("MyPrefs", MODE_PRIVATE);
        //cambiar el estado del booleano a true
        SharedPreferences.Editor mantenersesion = sharedPreferences.edit();
        mantenersesion.putBoolean("mantenersesion", true);
        mantenersesion.apply();
        int id_restS = sharedPreferences.getInt("restaurante_id", -1);
        int id_rest = getIntent().getIntExtra("restaurante_id", -1);
        // Si el id del restaurante no se encuentra en sharedPreferences, setea el id del intent
        if (id_rest != -1) {
            id_restS = id_rest;
        }
        //logs de todos los valores recibidos
        Log.d("log_vistaDueno2_id_rest", String.valueOf(id_rest));
        Log.d("log_vistaDueno2_id_restS", String.valueOf(id_restS));
        Log.d("log_vistaDueno2_id_rest_intent", String.valueOf(getIntent().getIntExtra("restaurante_id", -1)));
        Log.d("log_vistaDueno2_id_rest_shared", String.valueOf(sharedPreferences.getInt("restaurante_id", -1)));



        mapsDueFragment = new MapsDueFragment();
        settingsDuenoFragment = new SettingsDuenoFragment();
        platos_Fragment = new dueno_platos();
        bebidas_Fragment = new dueno_bebidas();

        // Agrega el nombre del restaurante al bundle
        Bundle bundle = new Bundle();
        bundle.putInt("restaurante_id", id_rest);
        bundle.putString("nombre_restaurante", "Nombre del Restaurante"); // Aquí deberías agregar el nombre del restaurante
        mapsDueFragment.setArguments(bundle);
        platos_Fragment.setArguments(bundle);
        bebidas_Fragment.setArguments(bundle);
        settingsDuenoFragment.setArguments(bundle);

        // Carga el fragmento de mapas como el inicial
        loadFragment(mapsDueFragment);

        BottomNavigationView bottomNavigationView = findViewById(R.id.bottom_navigation);
        bottomNavigationView.setOnNavigationItemSelectedListener(new BottomNavigationView.OnNavigationItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
                switch (item.getItemId()) {
                    case R.id.maps:
                        loadFragment(mapsDueFragment);
                        return true;
                    case R.id.ajustes:
                        loadFragment(settingsDuenoFragment);
                        return true;
                    case R.id.alimentos:
                        // Agregar el ID del restaurante al fragmento dueno_platos
                        Bundle bundlePlatos = new Bundle();
                        bundlePlatos.putInt("restaurante_id", id_rest);
                        bundlePlatos.putString("nombre_restaurante", nombreRestaurante); // Agrega esta línea
                        Log.d("id_rest_enviado_a_platosF", String.valueOf(id_rest));
                        Log.d("nombre_rest_enviado_a_platosF", nombreRestaurante);
                        platos_Fragment.setArguments(bundlePlatos);
                        loadFragment(platos_Fragment);
                        return true;
                    case R.id.bebidas:
                        // Agregar el ID del restaurante al fragmento dueno_bebidas
                        Bundle bundleBebidas = new Bundle();
                        bundleBebidas.putInt("restaurante_id", id_rest);
                        bundleBebidas.putString("nombre_restaurante", nombreRestaurante); // Agrega esta línea
                        Log.d("id_rest_enviado_a_bebidasF", String.valueOf(id_rest));
                        Log.d("nombre_rest_enviado_a_bebidasF", nombreRestaurante);
                        bebidas_Fragment.setArguments(bundleBebidas);
                        loadFragment(bebidas_Fragment);
                        return true;
                }
                transaction.commit();
                return false;
            }
        });

        fetchRestaurantDataFromDatabase(id_rest);
        // Añadir el callback para el manejo de retroceso
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (doubleBackToExitPressedOnce) {
                    // Si se presiona de nuevo dentro de los 2 segundos, finalizar la actividad
                    finishAffinity(); // Finaliza la actividad
                } else {
                    doubleBackToExitPressedOnce = true;
                    // Mostrar un mensaje de advertencia
                    Toast.makeText(vista_dueno2.this, "Presiona de nuevo para salir", Toast.LENGTH_SHORT).show();
                    new Handler().postDelayed(() -> doubleBackToExitPressedOnce = false, 2000);
                }
            }
        });
    }

    private void loadFragment(Fragment fragment) {
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();

        // Ocultar los fragmentos existentes
        if (mapsDueFragment != null && mapsDueFragment.isVisible()) {
            transaction.hide(mapsDueFragment);
        }
        if (platos_Fragment != null && platos_Fragment.isVisible()) {
            transaction.hide(platos_Fragment);
        }
        if (bebidas_Fragment != null && bebidas_Fragment.isVisible()) {
            transaction.hide(bebidas_Fragment);
        }
        if (settingsDuenoFragment != null && settingsDuenoFragment.isVisible()) {
            transaction.hide(settingsDuenoFragment);
        }

        // Mostrar el nuevo fragmento
        if (fragment != null) {
            if (fragment.isAdded()) {
                transaction.show(fragment);
            } else {
                transaction.add(R.id.fragment_container, fragment, fragment.getClass().getName());
            }
        }

        // Llamar a commit solo una vez al final
        transaction.commit();
    }


    private void fetchRestaurantDataFromDatabase(int restauranteId) {
        String controladorURL1 = Config.CONTROLADOR_URL + "cont_rest.php?restaurante_id=" + restauranteId;
        Log.d("url_rest", controladorURL1);
        String modeloURL2 = Config.MODELO_URL + "icono_rest.php?id=" + restauranteId;
        Log.d("url_sql", modeloURL2);
        Switch switchEstado = findViewById(R.id.boton_estado_rest);
        TextView nomrest_tx = findViewById(R.id.estado_rest);
        ImageView imageViewRestaurante = findViewById(R.id.icono_res);
        RequestQueue requestQueue2 = Volley.newRequestQueue(this);
        StringRequest stringRequest2 = new StringRequest(Request.Method.GET, modeloURL2, response -> {
            try {
                String imagen = response;
                imagen = imagen.replace("http://localhost", Config.ip);
                Log.d("imagen", imagen);
                if (!imagen.isEmpty()) {
                    Glide.with(this)
                            .load(imagen)
                            .into(imageViewRestaurante);
                }
            } catch (StringIndexOutOfBoundsException e) {
                e.printStackTrace();
            }
        }, error -> {
            Log.e("FetchDataError", "Error fetching data: " + error.toString());
        });
        requestQueue2.add(stringRequest2);

        RequestQueue requestQueue = Volley.newRequestQueue(this);
        StringRequest stringRequest = new StringRequest(Request.Method.GET, controladorURL1, response -> {
            try {
                JSONArray jsonArray = new JSONArray(response);
                for (int i = 0; i < jsonArray.length(); i++) {
                    JSONObject jsonObject = jsonArray.getJSONObject(i);
                    int restaurante_id = jsonObject.getInt("restaurante_id");


                    String nomRest = jsonObject.getString("nom_rest");
                    nombreRestaurante = jsonObject.getString("nom_rest");

                    Log.d("nom_rest_envistadueno", "Nombre: " + nomRest);
                    Log.d("nom_rest_envistadueno", "Nombre: " + nombreRestaurante);
                    int estadoRestaurante = jsonObject.getInt("estado");
                    initialRestaurantStatus = estadoRestaurante;

                    Log.d("Restaurante", "Nombre: " + nomRest);
                    Log.d("Restaurante", "Estado: " + estadoRestaurante);

                    TextView textViewNomRest = findViewById(R.id.nom_rest);
                    textViewNomRest.setText(nomRest);

                    // Crear un Bundle para pasar datos al fragmento
                    Bundle bundle = new Bundle();
                    bundle.putInt("restaurante_id", restaurante_id);
                    bundle.putString("nombre_restaurante", nombreRestaurante);
                    mapsDueFragment.setArguments(bundle);
                    platos_Fragment.setArguments(bundle);
                    bebidas_Fragment.setArguments(bundle);
                    settingsDuenoFragment.setArguments(bundle);

                    if (estadoRestaurante == 1) {
                        switchEstado.setChecked(true);
                        nomrest_tx.setText("Abierto");
                        switchEstado.getTrackDrawable().setColorFilter(Color.GREEN, PorterDuff.Mode.MULTIPLY);
                    } else {
                        switchEstado.setChecked(false);
                        nomrest_tx.setText("Cerrado");
                        switchEstado.getTrackDrawable().setColorFilter(Color.RED, PorterDuff.Mode.MULTIPLY);
                    }
                    switchEstado.setOnCheckedChangeListener((buttonView, isChecked) -> {
                        int nuevoEstado = isChecked ? 1 : 0;
                        sendRequest(restaurante_id, nuevoEstado);
                        if (isChecked) {
                            nomrest_tx.setText("Abierto");
                        } else {
                            nomrest_tx.setText("Cerrado");
                        }
                        if (onRestaurantStatusChangeListener != null) {
                            onRestaurantStatusChangeListener.onStatusChange(nuevoEstado);
                        }
                        updateSwitchState(nuevoEstado);
                    });

                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }, error -> {
            Log.e("FetchDataError", "Error fetching data: " + error.toString());
        });
        requestQueue.add(stringRequest);
    }


    private void sendRequest(int restauranteId, int estado) {
        String modeloURL = Config.MODELO_URL + "cambiar_estado.php?restaurante_id=" + restauranteId + "&estado=" + estado;
        Log.d("url_estado", modeloURL);
        RequestQueue requestQueue = Volley.newRequestQueue(this);
        StringRequest stringRequest = new StringRequest(Request.Method.GET, modeloURL, response -> {
        }, error -> {
        });

        requestQueue.add(stringRequest);
    }

    public void setOnRestaurantStatusChangeListener(OnRestaurantStatusChangeListener listener) {
        this.onRestaurantStatusChangeListener = listener;
    }

    public int getInitialRestaurantStatus() {
        return initialRestaurantStatus;
    }

    public void updateSwitchState(int estado) {
        Switch switchEstado = findViewById(R.id.boton_estado_rest);
        TextView nomrest_tx = findViewById(R.id.estado_rest);

        if (estado == 1) {
            switchEstado.setChecked(true);
            nomrest_tx.setText("Abierto");
            switchEstado.getTrackDrawable().setColorFilter(Color.GREEN, PorterDuff.Mode.MULTIPLY);
        } else {
            switchEstado.setChecked(false);
            nomrest_tx.setText("Cerrado");
            switchEstado.getTrackDrawable().setColorFilter(Color.RED, PorterDuff.Mode.MULTIPLY);
        }
    }

}

package com.example.foofmaps.clientes.restaurantes;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

import com.bumptech.glide.Glide;
import com.example.foofmaps.Config;
import com.example.foofmaps.R;
import com.example.foofmaps.clientes.restaurantes.fragments.bebidas_rest;
import com.example.foofmaps.clientes.restaurantes.fragments.platos_rest;
import com.google.android.material.bottomnavigation.BottomNavigationView;

public class MenuRest extends AppCompatActivity {
    private Fragment platosFragment;
    private Fragment bebidasFragment;
    private int restaurante_id;
    private String nom_rest;
    private int celular;
    private String imagen;

    private ImageView imageViewRestaurante;
    private TextView bannertop;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_menu_rest);

        Intent intent = getIntent();
        restaurante_id = intent.getIntExtra("restaurant_id", 0);
        nom_rest = intent.getStringExtra("restaurant_name");
        celular = intent.getIntExtra("restaurant_phone", 0);
        imagen = intent.getStringExtra("restaurant_image");

        Log.d("imagenmenurest", imagen);
        if (Config.ip.equals("http://192.168.100.5")) {
            imagen = imagen.replace("http://localhost", Config.ip);
        }

        bannertop = findViewById(R.id.bannertop);
        ImageButton whatsappButton = findViewById(R.id.btnWhatsApp);
        imageViewRestaurante = findViewById(R.id.imageViewRestaurante);

        bannertop.setText(nom_rest);
        whatsappButton.setOnClickListener(v -> openWhatsApp(String.valueOf(celular)));

        loadImage(imagen);

        if (savedInstanceState == null) {
            platosFragment = new platos_rest();
            bebidasFragment = new bebidas_rest();

            Bundle args = new Bundle();
            args.putInt("restaurant_id", restaurante_id);
            platosFragment.setArguments(args);
            bebidasFragment.setArguments(args);

            getSupportFragmentManager().beginTransaction()
                    .replace(R.id.contenedorlista, platosFragment)
                    .commit();
        } else {
            FragmentManager fragmentManager = getSupportFragmentManager();
            platosFragment = fragmentManager.getFragment(savedInstanceState, "platosFragment");
            bebidasFragment = fragmentManager.getFragment(savedInstanceState, "bebidasFragment");
            if (platosFragment == null) {
                platosFragment = new platos_rest();
                Bundle args = new Bundle();
                args.putInt("restaurant_id", restaurante_id);
                platosFragment.setArguments(args);
            }
            if (bebidasFragment == null) {
                bebidasFragment = new bebidas_rest();
                Bundle args = new Bundle();
                args.putInt("restaurant_id", restaurante_id);
                bebidasFragment.setArguments(args);
            }
        }

        BottomNavigationView bottomNavigationView = findViewById(R.id.platosybebidas);
        bottomNavigationView.setOnNavigationItemSelectedListener(item -> {
            Fragment fragment = null;
            switch (item.getItemId()) {
                case R.id.comidas:
                    fragment = platosFragment;
                    break;
                case R.id.bebidas:
                    fragment = bebidasFragment;
                    break;
            }
            if (fragment != null) {
                FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
                transaction.replace(R.id.contenedorlista, fragment);
                transaction.commitAllowingStateLoss();
                loadImage(imagen); // Recargar la imagen al cambiar de fragmento
            }
            return true;
        });
    }

    private void openWhatsApp(String celular) {
        String url = "https://wa.me/591" + celular;
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        startActivity(intent);
    }

    private void loadImage(String url) {
        Glide.with(this)
                .load(url)
                .into(imageViewRestaurante);
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadImage(imagen);
        bannertop.setText(nom_rest);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        FragmentManager fragmentManager = getSupportFragmentManager();
        if (platosFragment.isAdded()) {
            fragmentManager.putFragment(outState, "platosFragment", platosFragment);
        }
        if (bebidasFragment.isAdded()) {
            fragmentManager.putFragment(outState, "bebidasFragment", bebidasFragment);
        }
    }
}

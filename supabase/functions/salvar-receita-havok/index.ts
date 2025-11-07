// supabase/functions/salvar-receita-havok/index.ts

// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // --- ETAPA 1: AUTENTICAÇÃO E EXTRAÇÃO DOS DADOS DA RECEITA ---
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Usuário não autenticado.");

    // Extrai o JSON completo da receita enviado pelo app
    const { recipeData } = await req.json();
    if (!recipeData || typeof recipeData !== 'object' || !recipeData.nome) {
      throw new Error("Os dados da receita são inválidos.");
    }

    // --- ETAPA 2: SALVAR A RECEITA NO BANCO DE DADOS ---
    const { data: savedRecipe, error: insertError } = await supabaseClient
      .schema('bldr_club')
      .from('havok_recipes')
      .insert({
        user_id: user.id,
        recipe_data: recipeData,
        recipe_name: recipeData.nome, // Extrai o nome do JSON
      })
      .select()
      .single();

    if (insertError) {
      // Trata o caso de a receita já ter sido salva (conflito de chave única, se houver)
      if (insertError.code === '23505') {
         throw new Error("Esta receita já está na sua biblioteca.");
      }
      throw new Error(`Erro ao salvar a receita: ${insertError.message}`);
    }

    // --- ETAPA 3: RETORNAR MENSAGEM DE SUCESSO ---
    return new Response(JSON.stringify({ message: "Receita salva com sucesso!", data: savedRecipe }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
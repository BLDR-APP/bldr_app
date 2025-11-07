// supabase/functions/gerar-receita-havok/index.ts

// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GOOGLE_AI_MODEL = 'gemini-2.5-flash';

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // --- ETAPA 1: AUTENTICAÇÃO E BUSCA DOS DADOS DO USUÁRIO ---
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Usuário não autenticado.");

    // Extrai o pedido do usuário (ex: "frango e batata doce" ou "Pós-treino")
    const { userQuery } = await req.json();
    if (!userQuery || typeof userQuery !== 'string' || userQuery.trim() === '') {
      throw new Error("O pedido da receita está vazio ou inválido.");
    }

    // Busca as preferências alimentares do usuário para personalizar a receita
    const { data: profile, error: profileError } = await supabaseClient
      .from('user_profiles')
      .select('onboarding_data')
      .eq('id', user.id)
      .single();

    if (profileError || !profile || !profile.onboarding_data) {
      throw new Error(`Dados de onboarding do usuário não encontrados.`);
    }

    const dietaryPreferences = profile.onboarding_data.dietary_preferences?.join(', ') || 'Sem restrições';

    // --- ETAPA 2: CONSTRUÇÃO DO PROMPT PARA A IA ---
    const prompt = `
      Você é HAVOK, uma IA especialista em nutrição esportiva e culinária para o app BLDR.
      Sua tarefa é gerar uma receita saudável, prática e deliciosa baseada no pedido do usuário.

      Pedido do Usuário: "${userQuery}"
      Preferências Alimentares do Usuário: ${dietaryPreferences}

      Instruções:
      1. Interprete o pedido e as preferências do usuário para criar UMA receita.
      2. Crie um nome criativo e apetitoso para a receita.
      3. Forneça uma lista de ingredientes simples.
      4. Descreva o modo de preparo em passos claros e curtos.
      5. Forneça uma ESTIMATIVA dos macronutrientes (proteínas, carboidratos, gorduras) e calorias. É crucial que sejam valores aproximados.
      6. A resposta DEVE ser um objeto JSON válido, sem nenhum texto ou markdown antes ou depois.

      Estrutura do JSON de Resposta:
      {
        "nome": "Nome Criativo da Receita",
        "descricao": "Uma descrição curta e atrativa da receita.",
        "ingredientes": [
          "150g de peito de frango",
          "200g de batata doce",
          "1 colher de sopa de azeite"
        ],
        "preparo": [
          "Cozinhe a batata doce até ficar macia.",
          "Grelhe o frango com temperos.",
          "Sirva tudo junto."
        ],
        "macros": {
          "calorias_aprox": 450,
          "proteinas_g": 40,
          "carboidratos_g": 50,
          "gorduras_g": 10
        }
      }
    `;

    // --- ETAPA 3: CHAMADA PARA A API DO GOOGLE AI ---
    const googleApiKey = Deno.env.get("GOOGLE_AI_KEY");
    if (!googleApiKey) throw new Error("Chave de API do Google AI não configurada.");
    const aiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GOOGLE_AI_MODEL}:generateContent?key=${googleApiKey}`;
    const aiResponse = await fetch(aiApiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    });
    if (!aiResponse.ok) {
      const errorBody = await aiResponse.text();
      throw new Error(`Erro na API do Google AI: ${aiResponse.status} ${errorBody}`);
    }
    const aiData = await aiResponse.json();
    let recipeText = aiData.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!recipeText) throw new Error("A IA não retornou uma receita válida.");
    recipeText = recipeText.replace(/```json/g, '').replace(/```/g, '').trim();

    // --- ETAPA 4: RETORNAR A RECEITA GERADA PARA O APP ---
    // Nota: Por enquanto, não vamos salvar a receita no banco de dados.
    const recipeJson = JSON.parse(recipeText);
    return new Response(JSON.stringify(recipeJson), {
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
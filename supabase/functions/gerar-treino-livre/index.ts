// supabase/functions/gerar-treino-livre/index.ts

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
    // --- ETAPA 1: AUTENTICAÇÃO E EXTRAÇÃO DO PROMPT DO USUÁRIO ---
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Usuário não autenticado.");

    // Extrai o comando de texto enviado pelo app
    const { userPrompt } = await req.json();
    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim() === '') {
      throw new Error("O comando para gerar o treino está vazio ou inválido.");
    }

    // --- ETAPA 2: CONSTRUÇÃO DO PROMPT PARA A IA ---
    const prompt = `
      Você é HAVOK, uma IA de classe mundial especialista em personal training para o app BLDR.
      Sua tarefa é criar um plano de treino específico baseado em um pedido direto do usuário.

      Pedido do Usuário: "${userPrompt}"

      Instruções CRÍTICAS:
      1. Interprete o pedido do usuário e crie um treino que corresponda ao que foi solicitado.
      2. A segurança é prioridade. Evite exercícios de alto risco se não houver contexto sobre o nível do usuário.
      3. Crie um nome poderoso e motivador para o treino, em português, que reflita o pedido do usuário.
      4. Selecione de 5 a 8 exercícios.
      5. Defina séries e repetições adequadas.
      6. NÃO inclua aquecimento, descanso ou notas. Apenas a estrutura do treino.
      7. A resposta DEVE ser um objeto JSON válido, sem nenhum texto ou markdown antes ou depois.

      Estrutura do JSON de Resposta:
      {
        "nome": "Nome do Treino",
        "exercicios": [
          { "nome": "Nome do Exercício 1", "series": 4, "repeticoes": "8-12" },
          { "nome": "Nome do Exercício 2", "series": 3, "repeticoes": "10-15" }
        ]
      }
    `;

    // --- ETAPA 3: CHAMADA PARA A API DO GOOGLE AI (idêntica à função anterior) ---
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
    let workoutText = aiData.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!workoutText) throw new Error("A IA não retornou um treino válido.");
    workoutText = workoutText.replace(/```json/g, '').replace(/```/g, '').trim();

    // --- ETAPA 4: PROCESSAR E SALVAR O TREINO (idêntica à função anterior) ---
    const workoutJson = JSON.parse(workoutText);
    const { data: savedWorkout, error: insertError } = await supabaseClient
      .schema('bldr_club')
      .from('havok_workouts')
      .insert({
        user_id: user.id,
        workout_data: workoutJson,
        workout_name: workoutJson.nome,
      })
      .select()
      .single();
    if (insertError) throw new Error(`Erro ao salvar o treino: ${insertError.message}`);

    // --- ETAPA 5: RETORNAR O TREINO GERADO (idêntica à função anterior) ---
    return new Response(JSON.stringify(savedWorkout), {
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
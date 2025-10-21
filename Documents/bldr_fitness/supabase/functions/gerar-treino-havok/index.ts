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

    // Busca a coluna 'onboarding_data' da sua tabela 'user_profiles'
    const { data: profile, error: profileError } = await supabaseClient
      .from('user_profiles') // Nome da sua tabela de perfis
      .select('onboarding_data') // Buscando a coluna JSON
      .eq('id', user.id)
      .single();

    if (profileError || !profile || !profile.onboarding_data) {
      throw new Error(`Dados de onboarding do usuário não encontrados ou incompletos: ${profileError?.message}`);
    }

    const onboarding = profile.onboarding_data;

    // --- ETAPA 2: CONSTRUÇÃO DO PROMPT DETALHADO E SEGURO ---
    // Formatando os campos que são listas para texto legível
    const injuryText = (onboarding.injury_options?.length > 0) ? onboarding.injury_options.join(', ') : 'Nenhuma';
    const workoutTypesText = (onboarding.workout_types?.length > 0) ? onboarding.workout_types.join(', ') : 'Não especificado';
    const equipmentText = (onboarding.available_equipment?.length > 0) ? onboarding.available_equipment.join(', ') : 'Peso Corporal';

    const prompt = `
      Você é HAVOK, uma IA de classe mundial especialista em personal training para o app BLDR.
      Sua tarefa é criar um plano de treino altamente personalizado, eficaz e, acima de tudo, SEGURO.

      Dados Completos do Usuário (extraídos do onboarding):
      - Objetivo Principal: ${onboarding.fitness_goals}
      - Gênero: ${onboarding.gender}
      - Nível de Experiência: ${onboarding.experience_level}
      - Tipos de Treino Preferidos: ${workoutTypesText}
      - Equipamentos Disponíveis: ${equipmentText}
      - Duração Máxima por Treino (minutos): ${onboarding.time_constraints}
      - Frequência Semanal: ${onboarding.workout_frequency}
      - Lesões ou Limitações Reportadas: ${injuryText}

      Instruções CRÍTICAS:
      1. **SEGURANÇA É PRIORIDADE MÁXIMA:** Se o usuário listou lesões ou limitações (${injuryText}), EVITE OBRIGATORIAMENTE exercícios que possam forçar ou agravar essas áreas. Por exemplo, para uma lesão no tornozelo, evite saltos em caixa e sugira exercícios com apoio como leg press ou panturrilha sentado.
      2. Crie um nome poderoso e motivador para o treino, em português.
      3. Selecione de 5 a 8 exercícios baseados em TODOS os dados fornecidos.
      4. Defina séries e repetições adequadas para o objetivo e nível de experiência.
      5. NÃO inclua aquecimento, descanso ou notas. Apenas a estrutura do treino.
      6. A resposta DEVE ser um objeto JSON válido, sem nenhum texto, markdown (como \`\`\`json) ou comentários antes ou depois do JSON.

      Estrutura do JSON de Resposta:
      {
        "nome": "Nome do Treino",
        "exercicios": [
          { "nome": "Nome do Exercício 1", "series": 4, "repeticoes": "8-12" },
          { "nome": "Nome do Exercício 2", "series": 3, "repeticoes": "10-15" }
        ]
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
    let workoutText = aiData.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!workoutText) throw new Error("A IA não retornou um treino válido.");
    workoutText = workoutText.replace(/```json/g, '').replace(/```/g, '').trim();

    // --- ETAPA 4: PROCESSAR E SALVAR O TREINO NO BANCO DE DADOS ---
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

    // --- ETAPA 5: RETORNAR O TREINO GERADO PARA O APP ---
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
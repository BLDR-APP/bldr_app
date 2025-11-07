// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GOOGLE_AI_MODEL = 'gemini-2.5-flash'; // Você estava usando gemini-2.5-flash, mantido.

// --- INÍCIO DA ADIÇÃO: Lógica do havok_prompt.js colada aqui ---
/**
 * Gera o prompt de texto para a IA HAVOK com base nos dados do novo
 * fluxo de onboarding (15 etapas).
 *
 * @param {object} onboardingData - O objeto 'onboarding_data' salvo no perfil do usuário.
 * @returns {string} O prompt formatado para enviar à IA.
 */
function generateHavokPrompt(onboardingData: any): string { // Adicionado tipo 'any' para Deno/TypeScript
  // Extrai os dados do novo onboarding.
  // Assume valores padrão ou strings vazias se algo for nulo.

  // Dados de Nutrição (para contexto de objetivo)
  const mainGoal = onboardingData.main_goal || 'Equilíbrio';
  const goalPace = onboardingData.goal_pace || 'Moderado';

  // Dados de Treino (essenciais)
  const gender = onboardingData.gender || 'Não informado';
  const experience = onboardingData.experience_level || 'Iniciante';
  const freqDays = onboardingData.workout_frequency_days || 3;
  const duration = onboardingData.workout_duration_range || '45-60 min';
  const environment = onboardingData.workout_environment || 'Academia Completa';

  // Trata listas que podem ser nulas ou vazias
  const equipmentList = onboardingData.home_equipment || [];
  const focusList = onboardingData.muscle_focus || []; // ex: ['chest', 'shoulders']

  const split = onboardingData.split_preference || 'Deixe a HAVOK decidir';

  // --- Helpers de Texto ---

  // Cria texto descritivo para equipamentos
  let equipmentText = environment;
  if (environment === 'Casa com Equipamentos' && equipmentList.length > 0) {
    equipmentText = `Treino em casa usando apenas: ${equipmentList.join(', ')}`;
  } else if (environment === 'Casa com Equipamentos' && equipmentList.length === 0) {
    equipmentText = 'Treino em casa, mas o usuário não especificou equipamentos (assuma peso corporal ou halteres básicos se necessário).';
  }

  // Cria texto descritivo para o foco
  const focusText = focusList.length > 0
    ? `Priorizar o desenvolvimento de: ${focusList.join(', ')}`
    : 'Foco equilibrado no corpo inteiro';


  // --- Montagem do Prompt ---
  const prompt = `
  Você é HAVOK, uma IA de classe mundial especialista em personal training para o app BLDR.
  Sua tarefa é criar um plano de treino altamente personalizado, eficaz e seguro, baseado nos dados detalhados do usuário.

  Dados Completos do Usuário (Novo Fluxo de Onboarding):
  - Gênero: ${gender}
  - Objetivo Principal: ${mainGoal} (Ritmo: ${goalPace})
  - Nível de Experiência: ${experience}
  - Frequência de Treino: ${freqDays} dias por semana
  - Duração por Treino: ${duration}
  - Ambiente de Treino: ${equipmentText}
  - Foco Muscular Principal: ${focusText}
  - Preferência de Estrutura (Split): ${split}

  Instruções CRÍTICAS:
  1. **Se a Preferência de Estrutura for 'Deixe a HAVOK decidir'**: Crie a melhor estrutura (split) possível que combine a Frequência (${freqDays} dias) com o Foco Muscular (${focusText}).
     Ex: Se a frequência for 3 dias e o foco for 'Upper Body', um split 'Full Body' 3x/semana com ênfase em superiores é ideal.
     Ex: Se a frequência for 5 dias e o foco for 'Ombros e Pernas', um split 'Push/Pull/Legs/Upper/Lower' pode ser bom.
  2. **Se a Preferência de Estrutura for um split específico (ex: 'Push/Pull/Legs')**: Respeite essa estrutura. Crie um treino para o DIA 1 desse split, garantindo que ele se encaixe na frequência e nos focos pedidos. (Atenção: Gere apenas UM dia de treino).
  3. **Adapte ao Ambiente**: Se for 'Academia Completa', use máquinas, halteres e barras. Se for 'Peso Corporal', use apenas exercícios bodyweight. Se for 'Casa com Equipamentos', use APENAS os equipamentos listados em ${equipmentText}.
  4. **Adapte ao Objetivo**: Se o objetivo for 'Perder Gordura', favoreça repetições ligeiramente mais altas (ex: 10-15) e talvez inclua exercícios compostos. Se for 'Ganhar Massa Muscular', foque na faixa de hipertrofia clássica (ex: 8-12 reps).
  5. Crie um nome poderoso e motivador para o treino (DIA 1), em português.
  6. Selecione de 5 a 8 exercícios baseados em TODOS os dados.
  7. Defina séries e repetições adequadas.
  8. NÃO inclua aquecimento, descanso ou notas. Apenas a estrutura do treino.
  9. A resposta DEVE ser um objeto JSON válido, sem nenhum texto, markdown (como \`\`\`json) ou comentários antes ou depois do JSON.

  Estrutura do JSON de Resposta:
  {
    "nome": "Nome do Treino (Ex: Protocolo Hipertrofia - Foco Peito)",
    "exercicios": [
      { "nome": "Nome do Exercício 1", "series": 4, "repeticoes": "8-12" },
      { "nome": "Nome do Exercício 2", "series": 3, "repeticoes": "10-15" }
    ]
  }
`;

  return prompt;
}
// --- FIM DA ADIÇÃO ---


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

    // --- ETAPA 2: CONSTRUÇÃO DO PROMPT (MODIFICADO) ---
    // Removemos a lógica antiga e chamamos a nova função
    const prompt = generateHavokPrompt(onboarding);
    // --- FIM DA MODIFICAÇÃO ---


    // --- ETAPA 3: CHAMADA PARA A API DO GOOGLE AI ---
    const googleApiKey = Deno.env.get("GOOGLE_AI_KEY");
    if (!googleApiKey) throw new Error("Chave de API do Google AI não configurada.");
    const aiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GOOGLE_AI_MODEL}:generateContent?key=${googleApiKey}`;

    console.log("Enviando prompt para a IA:", prompt); // Adiciona log para debug

    const aiResponse = await fetch(aiApiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    });

    if (!aiResponse.ok) {
      const errorBody = await aiResponse.text();
      console.error("Erro da API do Google AI:", errorBody); // Log detalhado
      throw new Error(`Erro na API do Google AI: ${aiResponse.status} ${errorBody}`);
    }

    const aiData = await aiResponse.json();
    let workoutText = aiData.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!workoutText) {
       console.error("Resposta da IA vazia ou mal formatada:", JSON.stringify(aiData, null, 2));
       throw new Error("A IA não retornou um treino válido.");
    }

    workoutText = workoutText.replace(/```json/g, '').replace(/```/g, '').trim();

    // --- ETAPA 4: PROCESSAR E SALVAR O TREINO NO BANCO DE DADOS ---
    const workoutJson = JSON.parse(workoutText);
    const { data: savedWorkout, error: insertError } = await supabaseClient
      .schema('bldr_club') // Certifique-se que o schema 'bldr_club' existe e tem a tabela
      .from('havok_workouts')
      .insert({
        user_id: user.id,
        workout_data: workoutJson,
        workout_name: workoutJson.nome,
        // Adiciona o prompt usado para debug, se a coluna existir
        // prompt_used: prompt
      })
      .select()
      .single();

    if (insertError) {
       console.error("Erro ao salvar no Supabase:", insertError);
       throw new Error(`Erro ao salvar o treino: ${insertError.message}`);
    }

    // --- ETAPA 5: RETORNAR O TREINO GERADO PARA O APP ---
    return new Response(JSON.stringify(savedWorkout), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Erro fatal na Edge Function:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
// supabase/functions/link-professional-client/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  try {
    // 1. Cria um cliente para autenticar o usuário que fez a chamada
    const userClient: SupabaseClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: req.headers.get('Authorization')! } },
    });

    const { data: { user } } = await userClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: 'Acesso não autorizado' }), { status: 401 });
    }

    // 2. Cria um cliente SEPARADO com privilégios de administrador para operar no DB
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { clientEmail } = await req.json();
    if (!clientEmail) {
      return new Response(JSON.stringify({ error: 'E-mail do cliente é obrigatório' }), { status: 400 });
    }

    // 3. Usa o cliente ADMIN para encontrar o cliente (ignora RLS)
    const { data: clientProfile, error: findError } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('email', clientEmail.toLowerCase().trim())
      .single();

    if (findError || !clientProfile) {
      throw new Error('Usuário cliente não encontrado.');
    }

    // 4. Usa o cliente ADMIN para criar o vínculo
    const { error: linkError } = await supabaseAdmin
      .schema('bldr_club')
      .from('professional_clients')
      .insert({
        professional_user_id: user.id,      // ID do profissional logado
        client_user_id: clientProfile.id,   // ID do cliente encontrado
      });

    if (linkError) {
      if (linkError.code === '23505') {
        throw new Error('Este cliente já foi adicionado.');
      }
      throw linkError;
    }

    return new Response(JSON.stringify({ message: 'Cliente adicionado com sucesso!' }), { status: 200 });

  } catch (error) {
    console.error('Error in link-professional-client function:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
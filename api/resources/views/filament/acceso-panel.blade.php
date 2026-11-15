<x-filament-panels::page.simple>
    <div class="space-y-6">
        @if (session('correo_administracion'))
            <form method="POST" action="{{ route('admin.verificar') }}" class="space-y-4">
                @csrf
                <p>Si tu cuenta está habilitada, el código llegará a tu correo UTB. Vence en 10 minutos.</p>
                <label for="codigo" class="block font-medium">Código de seis dígitos</label>
                <x-filament::input.wrapper :valid="! $errors->has('codigo')">
                    <x-filament::input id="codigo" name="codigo" type="text" inputmode="numeric"
                        autocomplete="one-time-code" pattern="[0-9]{6}" minlength="6" maxlength="6" required />
                </x-filament::input.wrapper>
                @error('codigo')
                    <p role="alert" class="text-danger-600">{{ $message }}</p>
                @enderror
                <x-filament::button type="submit">Entrar al panel</x-filament::button>
            </form>
        @endif
        <form method="POST" action="{{ route('admin.codigo') }}" class="space-y-4">
            @csrf
            <label for="correo" class="block font-medium">Correo institucional</label>
            <x-filament::input.wrapper :valid="! $errors->has('correo')">
                <x-filament::input id="correo" name="correo" type="email" autocomplete="email" maxlength="254"
                    :value="old('correo', session('correo_administracion'))" required />
            </x-filament::input.wrapper>
            @error('correo')
                <p role="alert" class="text-danger-600">{{ $message }}</p>
            @enderror
            <x-filament::button type="submit" :outlined="(bool) session('correo_administracion')">
                {{ session('correo_administracion') ? 'Pedir otro código' : 'Enviarme el código' }}
            </x-filament::button>
        </form>
    </div>
</x-filament-panels::page.simple>

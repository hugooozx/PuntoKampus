<?php

namespace App\Filament\Pages;

use Filament\Facades\Filament;
use Filament\Pages\SimplePage;

class AccesoPanel extends SimplePage
{
    protected static ?string $title = 'Acceso a administración';

    protected string $view = 'filament.acceso-panel';

    public function mount(): void
    {
        if (Filament::auth()->user()?->canAccessPanel(Filament::getCurrentPanel())) {
            $this->redirectRoute('filament.admin.resources.reportes.index');
        }
    }
}

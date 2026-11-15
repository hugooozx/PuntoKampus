<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $asunto }}</title>
</head>
<body style="margin:0;background:#f7f5f2;color:#1b1b19;font:16px/1.5 Arial,sans-serif">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f7f5f2">
        <tr><td align="center" style="padding:32px 16px">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#fff;border:1px solid #ded8d1;border-radius:18px">
                <tr><td style="padding:28px 24px">
                    <p style="margin:0 0 24px;font-weight:bold;font-size:20px">
                        <span aria-hidden="true" style="display:inline-block;background:#ae4500;color:#fff;border-radius:9px;padding:2px 9px">pk</span>
                        PuntoKampus
                    </p>
                    <h1 style="margin:0 0 8px;font-size:26px;line-height:1.2">Tu código de verificación</h1>
                    <p style="margin:0 0 20px">Usa este código para {{ $accion }}.</p>
                    <p style="margin:0 0 20px;padding:12px 8px;text-align:center;background:#fff0e4;color:#793300;border-radius:12px;font:bold 30px/1.4 'Courier New',monospace;letter-spacing:4px">{{ $codigo }}</p>
                    <p style="margin:0 0 8px"><strong>Vence en 10 minutos.</strong> No compartas el código con nadie.</p>
                    <p style="margin:0;color:#575752">Si no solicitaste este código, puedes ignorar el correo.</p>
                    <p style="margin:24px 0 0;padding-top:16px;border-top:1px solid #ded8d1;color:#575752;font-size:14px">PuntoKampus · Comunidad UTB</p>
                </td></tr>
            </table>
        </td></tr>
    </table>
</body>
</html>

using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Controllers
{
    public class TarifasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioTarifas repositorioTarifas;

        // Conceptos que SOLO deben aparecer en pantalla de IMPRESORA
        private static readonly HashSet<string> ConceptosSoloImpresora = new(StringComparer.OrdinalIgnoreCase)
        {
            "PRINT_HOUR",
            "POST_HOUR",
            "MATERIAL_GENERAL_PRN_GLOBAL"
        };

        // Conceptos que SOLO deben aparecer en pantalla de INVENTARIO
        private static readonly HashSet<string> ConceptosSoloInventario = new(StringComparer.OrdinalIgnoreCase)
        {
            "MATERIAL_UNIT",
            "MATERIAL_GENERAL_INV_GLOBAL"
        };

        public TarifasController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioTarifas repositorioTarifas
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioTarifas = repositorioTarifas;
        }

        private static string StripLeadingId(string? display)
        {
            if (string.IsNullOrWhiteSpace(display)) return "";
            // Ej: "12 - PLA - Rojo - ..."
            var parts = display.Split(" - ", 2, StringSplitOptions.RemoveEmptyEntries);
            return parts.Length == 2 ? parts[1].Trim() : display.Trim();
        }

        // GET: /Tarifas/Inventario?inventarioId=123
        [HttpGet]
        public async Task<IActionResult> Inventario(int inventarioId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            // 1) Traer display del inventario (sin cambiar SPs)
            var invSelector = (await repositorioTarifas.SelectorInventarios(loginId))
                .FirstOrDefault(x => x.InventarioId == inventarioId);

            var invNombre = invSelector != null
                ? StripLeadingId(invSelector.Display)
                : $"#{inventarioId}";

            // 2) Conceptos filtrados: en inventario NO muestres los de impresora
            var conceptos = (await repositorioTarifas.ObtenerConceptos())
                .Where(c => !ConceptosSoloImpresora.Contains(c.Codigo))
                .ToList();

            var tarifas = (await repositorioTarifas.ObtenerPorInventario(inventarioId, loginId)).ToList();

            var vm = new TarifaScopeViewModel
            {
                ScopeType = TarifaScopeType.Inventario,
                ScopeId = inventarioId,
                ScopeTitulo = invSelector != null
                    ? $"Tarifas — Inventario: {invNombre}"
                    : $"Tarifas — Inventario #{inventarioId}",
                Conceptos = conceptos,
                Tarifas = tarifas
            };

            return View("Scope", vm);
        }

        // GET: /Tarifas/Impresora?impresoraId=7
        [HttpGet]
        public async Task<IActionResult> Impresora(int impresoraId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            // 1) Traer display de la impresora (sin cambiar SPs)
            var impSelector = (await repositorioTarifas.SelectorImpresoras(loginId))
                .FirstOrDefault(x => x.ImpresoraId == impresoraId);

            var impNombreBonito = "";
            if (impSelector != null)
            {
                impNombreBonito = $"{impSelector.Nombre} {impSelector.Modelo}".Replace("  ", " ").Trim();
                if (string.IsNullOrWhiteSpace(impNombreBonito))
                    impNombreBonito = StripLeadingId(impSelector.Display);
            }

            // 2) Conceptos filtrados: en impresora NO muestres los de inventario
            var conceptos = (await repositorioTarifas.ObtenerConceptos())
                .Where(c => !ConceptosSoloInventario.Contains(c.Codigo))
                .ToList();

            var tarifas = (await repositorioTarifas.ObtenerPorImpresora(impresoraId, loginId)).ToList();

            var vm = new TarifaScopeViewModel
            {
                ScopeType = TarifaScopeType.Impresora,
                ScopeId = impresoraId,
                ScopeTitulo = impSelector != null
                    ? $"Tarifas — Impresora: {impNombreBonito}"
                    : $"Tarifas — Impresora #{impresoraId}",
                Conceptos = conceptos,
                Tarifas = tarifas
            };

            return View("Scope", vm);
        }

        // GET: /Tarifas/Historico?tarifaId=999
        [HttpGet]
        public async Task<IActionResult> Historico(int tarifaId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();
            var historico = await repositorioTarifas.ObtenerHistorico(tarifaId, loginId);
            return Json(historico);
        }

        // POST: /Tarifas/Crear
        [HttpPost]
        public async Task<IActionResult> Crear([FromBody] TarifaCrearDto dto)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            // Validación mínima para evitar basura:
            var tieneInventario = dto.InventarioId.HasValue && dto.InventarioId.Value > 0;
            var tieneImpresora = dto.ImpresoraId.HasValue && dto.ImpresoraId.Value > 0;

            if (tieneInventario == tieneImpresora) // ambos true o ambos false
            {
                return Json(new { result = "error", message = "Scope inválido: envía InventarioId o ImpresoraId (solo uno)." });
            }

            if (string.IsNullOrWhiteSpace(dto.TarifaConceptoCodigo))
                return Json(new { result = "error", message = "Falta TarifaConceptoCodigo." });

            if (dto.Monto < 0)
                return Json(new { result = "error", message = "Monto inválido (>= 0)." });

            dto.Moneda = string.IsNullOrWhiteSpace(dto.Moneda) ? "MXN" : dto.Moneda.Trim().ToUpperInvariant();
            dto.Nombre = dto.Nombre ?? "";
            dto.Orden = dto.Orden <= 0 ? 100 : dto.Orden;

            var res = await repositorioTarifas.Crear(dto, loginId);
            return Json(new { result = res.result, message = res.message, tarifaId = res.TarifaId });
        }

        // POST: /Tarifas/Actualizar
        [HttpPost]
        public async Task<IActionResult> Actualizar([FromBody] TarifaActualizarDto dto)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            if (dto.TarifaId <= 0)
                return Json(new { result = "error", message = "TarifaId inválido." });

            if (dto.Monto < 0)
                return Json(new { result = "error", message = "Monto inválido (>= 0)." });

            dto.Moneda = string.IsNullOrWhiteSpace(dto.Moneda) ? "MXN" : dto.Moneda.Trim().ToUpperInvariant();

            var res = await repositorioTarifas.Actualizar(dto, loginId);
            return Json(new { result = res.result, message = res.message });
        }

        // POST: /Tarifas/Eliminar
        [HttpPost]
        public async Task<IActionResult> Eliminar([FromBody] TarifaEliminarDto dto)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            if (dto.TarifaId <= 0)
                return Json(new { result = "error", message = "TarifaId inválido." });

            var res = await repositorioTarifas.Eliminar(dto.TarifaId, loginId);
            return Json(new { result = res.result, message = res.message });
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var inv = (await repositorioTarifas.SelectorInventarios(loginId)).ToList();
            var imp = (await repositorioTarifas.SelectorImpresoras(loginId)).ToList();

            var vm = new TarifasIndexViewModel
            {
                Inventarios = inv,
                Impresoras = imp
            };

            return View(vm);
        }
    }
}
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Controllers
{
    public class TarifasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioTarifas repositorioTarifas;

        public TarifasController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioTarifas repositorioTarifas
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioTarifas = repositorioTarifas;
        }

        // GET: /Tarifas/Inventario?inventarioId=123
        [HttpGet]
        public async Task<IActionResult> Inventario(int inventarioId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var conceptos = (await repositorioTarifas.ObtenerConceptos()).ToList();
            var tarifas = (await repositorioTarifas.ObtenerPorInventario(inventarioId, loginId)).ToList();

            var vm = new TarifaScopeViewModel
            {
                ScopeType = TarifaScopeType.Inventario,
                ScopeId = inventarioId,
                ScopeTitulo = $"Tarifas — Inventario #{inventarioId}",
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

            var conceptos = (await repositorioTarifas.ObtenerConceptos()).ToList();
            var tarifas = (await repositorioTarifas.ObtenerPorImpresora(impresoraId, loginId)).ToList();

            var vm = new TarifaScopeViewModel
            {
                ScopeType = TarifaScopeType.Impresora,
                ScopeId = impresoraId,
                ScopeTitulo = $"Tarifas — Impresora #{impresoraId}",
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
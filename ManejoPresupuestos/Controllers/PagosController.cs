using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    [Permiso("Pagos")]
    public class PagosController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioPagos repositorioPagos;
        private readonly IRepositorioCotizaciones repositorioCotizaciones;

        public PagosController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioPagos repositorioPagos,
            IRepositorioCotizaciones repositorioCotizaciones
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioPagos = repositorioPagos;
            this.repositorioCotizaciones = repositorioCotizaciones;
        }

        [HttpGet]
        public async Task<IActionResult> Index(int cotizacionId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cotizacion = await repositorioCotizaciones.ObtenerPorId(usuarioId, cotizacionId);

            if (cotizacion is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var pagos = await repositorioPagos.ObtenerPorCotizacion(usuarioId, cotizacionId);
            ViewBag.Cotizacion = cotizacion;
            return View(pagos);
        }

        [HttpGet]
        public async Task<IActionResult> Crear(int cotizacionId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cotizacion = await repositorioCotizaciones.ObtenerPorId(usuarioId, cotizacionId);

            if (cotizacion is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var modelo = new PagoEdicionViewModel
            {
                CotizacionId = cotizacionId,
                FechaPago = DateTime.Today
            };

            modelo.Tipos = await ObtenerTiposSelect();
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(PagoEdicionViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
            {
                modelo.Tipos = await ObtenerTiposSelect();
                return View(modelo);
            }

            var result = await repositorioPagos.Guardar(usuarioId, modelo);

            if (result.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError("", result.message);
                modelo.Tipos = await ObtenerTiposSelect();
                return View(modelo);
            }

            return RedirectToAction("Index", new { cotizacionId = modelo.CotizacionId });
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int cotizacionId, int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pago = await repositorioPagos.ObtenerPorId(usuarioId, cotizacionId, id);

            if (pago is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var modelo = new PagoEdicionViewModel
            {
                PagoId = pago.PagoId,
                CotizacionId = pago.CotizacionId,
                PagoTipoId = pago.PagoTipoId,
                Monto = pago.Monto,
                FechaPago = pago.FechaPago,
                Metodo = pago.Metodo,
                Referencia = pago.Referencia,
                Notas = pago.Notas
            };

            modelo.Tipos = await ObtenerTiposSelect();
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(PagoEdicionViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
            {
                modelo.Tipos = await ObtenerTiposSelect();
                return View(modelo);
            }

            var result = await repositorioPagos.Guardar(usuarioId, modelo);

            if (result.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError("", result.message);
                modelo.Tipos = await ObtenerTiposSelect();
                return View(modelo);
            }

            return RedirectToAction("Index", new { cotizacionId = modelo.CotizacionId });
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int cotizacionId, int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pago = await repositorioPagos.ObtenerPorId(usuarioId, cotizacionId, id);

            if (pago is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(pago);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarPago(int cotizacionId, int pagoId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioPagos.Borrar(usuarioId, cotizacionId, pagoId);
            return RedirectToAction("Index", new { cotizacionId });
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerTiposSelect()
        {
            var tipos = await repositorioPagos.ObtenerTipos();
            return tipos.Select(x => new SelectListItem(x.Nombre, x.PagoTipoId.ToString()));
        }
    }
}

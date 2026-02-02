using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    public class CotizacionesController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioCotizaciones repositorioCotizaciones;
        private readonly IRepositorioPagos repositorioPagos;
        private readonly IRepositorioProductos repositorioProductos;

        public CotizacionesController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioCotizaciones repositorioCotizaciones,
            IRepositorioPagos repositorioPagos,
            IRepositorioProductos repositorioProductos
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioCotizaciones = repositorioCotizaciones;
            this.repositorioPagos = repositorioPagos;
            this.repositorioProductos = repositorioProductos;
        }

        [HttpGet]
        public async Task<IActionResult> Index(int pedidoId = 0)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cotizaciones = await repositorioCotizaciones.ObtenerTodos(usuarioId, pedidoId);
            ViewBag.PedidoId = pedidoId;
            return View(cotizaciones);
        }

        [HttpGet]
        public async Task<IActionResult> Crear(int pedidoId = 0)
        {
            var modelo = new CotizacionEdicionViewModel
            {
                PedidoId = pedidoId,
                CotizacionEstatusId = 1
            };

            modelo.Estatus = await ObtenerEstatusSelect();
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(CotizacionEdicionViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
            {
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            var result = await repositorioCotizaciones.GuardarCotizacion(usuarioId, modelo);

            if (result.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError("", result.message);
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            var cotizacionId = result.elementoId;

            if (cotizacionId <= 0)
            {
                ModelState.AddModelError("", "La cotización se guardó, pero el SP no devolvió el ID (elementoId). Revisa procAlteraCotizacion.");
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            modelo.Items = modelo.Items ?? new List<CotizacionItemEdicionViewModel>();
            var itemsResult = await repositorioCotizaciones.GuardarItems(usuarioId, cotizacionId, modelo.Items);

            if (itemsResult.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError("", itemsResult.message);
                modelo.CotizacionId = cotizacionId;
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            return RedirectToAction("Detalles", new { id = cotizacionId });
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cotizacion = await repositorioCotizaciones.ObtenerPorId(usuarioId, id);

            if (cotizacion is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var items = await repositorioCotizaciones.ObtenerItems(usuarioId, id);

            var modelo = new CotizacionEdicionViewModel
            {
                CotizacionId = cotizacion.CotizacionId,
                PedidoId = cotizacion.PedidoId,
                CotizacionEstatusId = cotizacion.CotizacionEstatusId,
                FechaVigencia = cotizacion.FechaVigencia,
                Notas = cotizacion.Notas,
                Items = items.Select(x => new CotizacionItemEdicionViewModel
                {
                    CotizacionItemId = x.CotizacionItemId,
                    ConceptoTipoId = x.ConceptoTipoId,
                    ProductoId = x.ProductoId,
                    Concepto = x.Concepto,
                    Cantidad = x.Cantidad,
                    PrecioUnitario = x.PrecioUnitario,
                    Notas = x.Notas
                }).ToList()
            };

            modelo.Estatus = await ObtenerEstatusSelect();
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(CotizacionEdicionViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
            {
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            var result = await repositorioCotizaciones.GuardarCotizacion(usuarioId, modelo);

            if (result.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError("", result.message);
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            var itemsResult = await repositorioCotizaciones.GuardarItems(usuarioId, modelo.CotizacionId, modelo.Items ?? new List<CotizacionItemEdicionViewModel>());

            if (itemsResult.result != ResultProcedureType.SUCCESS)
            {
                ModelState.AddModelError("", itemsResult.message);
                modelo.Estatus = await ObtenerEstatusSelect();
                return View(modelo);
            }

            return RedirectToAction("Detalles", new { id = modelo.CotizacionId });
        }

        [HttpGet]
        public async Task<IActionResult> Detalles(int id)
        {
            if (id <= 0) return RedirectToAction("NoEncontrado", "Home");

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cotizacion = await repositorioCotizaciones.ObtenerPorId(usuarioId, id);

            if (cotizacion is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var items = await repositorioCotizaciones.ObtenerItems(usuarioId, id);
            var pagos = await repositorioPagos.ObtenerPorCotizacion(usuarioId, id);

            var modelo = new CotizacionDetalleViewModel
            {
                Cotizacion = cotizacion,
                Items = items,
                Pagos = pagos
            };

            return View(modelo);
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cotizacion = await repositorioCotizaciones.ObtenerPorId(usuarioId, id);

            if (cotizacion is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(cotizacion);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarCotizacion(int cotizacionId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var result = await repositorioCotizaciones.Borrar(usuarioId, cotizacionId);

            if (result.result != ResultProcedureType.SUCCESS)
            {
                return RedirectToAction("Detalles", new { id = cotizacionId });
            }

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> ObtenerProductos()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var productos = await repositorioProductos.ObtenerTodos(usuarioId);
            return Json(productos);
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerEstatusSelect()
        {
            var estatus = await repositorioCotizaciones.ObtenerEstatus();
            return estatus.Select(x => new SelectListItem(x.Nombre, x.CotizacionEstatusId.ToString()));
        }
    }
}

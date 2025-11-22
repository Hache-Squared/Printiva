using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class VentaCreacionViewModel : Venta
    {
        public IEnumerable<SelectListItem> Clientes { get; set; }
        public IEnumerable<SelectListItem> Recetas { get; set; }
        public IEnumerable<VentaReceta> VentaRecetas { get; set; }
    }
}

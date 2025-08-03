using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class InventarioCreacionViewModel : Inventario
    {
        public IEnumerable<SelectListItem> Marcas { get; set; }
        public IEnumerable<SelectListItem> Tipos { get; set; }
        public IEnumerable<SelectListItem> Nombres { get; set; }
        public IEnumerable<SelectListItem> Colores { get; set; }
        public IEnumerable<SelectListItem> Unidades { get; set; }
    }
}
